import SwiftUI
import AppKit

struct RouteRulesView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @State private var showAddSheet = false
    @State private var editingRule: RouteRule? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            toolbar
            
            // 规则列表
            ScrollView {
                VStack(spacing: 10) {
                    if networkManager.routeRules.isEmpty {
                        emptyRulesState
                    } else {
                        ForEach(networkManager.routeRules) { rule in
                            RouteRuleRow(rule: rule, onEdit: {
                                editingRule = rule
                            }, onDelete: {
                                deleteRule(rule)
                            }, onToggle: { enabled in
                                toggleRule(rule, enabled: enabled)
                            })
                        }
                    }
                }
                .padding(24)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddRouteRuleSheet(onSave: { newRule in
                networkManager.routeRules.append(newRule)
                networkManager.saveRules()
            })
            .environmentObject(networkManager)
        }
        .sheet(item: $editingRule) { rule in
            EditRouteRuleSheet(rule: rule, onSave: { updatedRule in
                if let index = networkManager.routeRules.firstIndex(where: { $0.id == updatedRule.id }) {
                    networkManager.routeRules[index] = updatedRule
                    networkManager.saveRules()
                }
            })
            .environmentObject(networkManager)
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack(spacing: 10) {
            Button(action: { showAddSheet = true }) {
                Label("添加规则", systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(GlowButtonStyle(color: .cyan))
            
            Spacer()
            
            Button(action: {
                networkManager.applyAllRules()
            }) {
                Label("全部应用", systemImage: "play.fill")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(GlowButtonStyle(color: .green))
            .disabled(networkManager.routeRules.isEmpty)
            
            Button(action: {
                networkManager.clearAllRoutes()
            }) {
                Label("清除路由", systemImage: "trash")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(GlowButtonStyle(color: .red))
            .disabled(networkManager.routeRules.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.03))
    }
    
    // MARK: - Empty State
    
    private var emptyRulesState: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 48, weight: .thin))
                .foregroundColor(.white.opacity(0.3))
            
            Text("暂无路由规则")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            Text("点击「添加规则」来创建 IP 路由规则，\n指定特定 IP 走 Wi-Fi 或有线网络")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
            
            Button(action: { showAddSheet = true }) {
                Label("添加第一条规则", systemImage: "plus")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    // MARK: - Actions
    
    private func deleteRule(_ rule: RouteRule) {
        _ = networkManager.removeRoute(rule)
        networkManager.routeRules.removeAll { $0.id == rule.id }
        networkManager.saveRules()
    }
    
    private func toggleRule(_ rule: RouteRule, enabled: Bool) {
        if let index = networkManager.routeRules.firstIndex(where: { $0.id == rule.id }) {
            networkManager.routeRules[index].isEnabled = enabled
            
            if enabled {
                _ = networkManager.addRoute(networkManager.routeRules[index])
            } else {
                _ = networkManager.removeRoute(rule)
            }
            
            networkManager.saveRules()
        }
    }
}

// MARK: - Route Rule Row

struct RouteRuleRow: View {
    let rule: RouteRule
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggle: (Bool) -> Void
    
    @State private var isHovered = false
    @State private var isEnabled: Bool
    
    init(rule: RouteRule, onEdit: @escaping () -> Void, onDelete: @escaping () -> Void, onToggle: @escaping (Bool) -> Void) {
        self.rule = rule
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onToggle = onToggle
        self._isEnabled = State(initialValue: rule.isEnabled)
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // 启用开关
            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.7)
                .onChange(of: isEnabled) { _, newValue in
                    onToggle(newValue)
                }
            
            // 规则信息
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(rule.destination)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(isEnabled ? .white : .white.opacity(0.4))
                    
                    if rule.subnetMask != "255.255.255.255" {
                        Text("/ \(rule.subnetMask)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                
                if !rule.note.isEmpty {
                    Text(rule.note)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
            
            Spacer()
            
            // 箭头指示
            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
            
            // 目标接口
            HStack(spacing: 6) {
                let ifType = getInterfaceType(rule.interfaceDisplayName)
                Image(systemName: ifType.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(getInterfaceColor(ifType))
                
                Text(rule.interfaceDisplayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isEnabled ? .white : .white.opacity(0.4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(getInterfaceColor(getInterfaceType(rule.interfaceDisplayName)).opacity(0.15))
            .clipShape(Capsule())
            
            // 操作按钮
            HStack(spacing: 4) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.red.opacity(0.7))
                        .frame(width: 28, height: 28)
                        .background(Color.red.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .opacity(isHovered ? 1 : 0.3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isHovered ? 0.07 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private func getInterfaceType(_ name: String) -> InterfaceType {
        if name.lowercased().contains("wi-fi") || name.lowercased().contains("wifi") {
            return .wifi
        } else if name.lowercased().contains("ethernet") || name.lowercased().contains("以太网") || name.lowercased().contains("thunderbolt") {
            return .ethernet
        }
        return .other
    }
    
    private func getInterfaceColor(_ type: InterfaceType) -> Color {
        switch type {
        case .wifi: return .cyan
        case .ethernet: return .green
        case .other: return .gray
        }
    }
}

// MARK: - Add Route Rule Sheet

struct AddRouteRuleSheet: View {
    @EnvironmentObject var networkManager: NetworkManager
    @Environment(\.dismiss) var dismiss
    
    let onSave: (RouteRule) -> Void
    
    @State private var destination = ""
    @State private var subnetMask = "255.255.255.255"
    @State private var selectedInterface: NetworkInterface?
    @State private var note = ""
    @State private var isSingleHost = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Sheet 头部
            HStack {
                Text("添加路由规则")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 目标 IP
                    VStack(alignment: .leading, spacing: 6) {
                        Text("目标 IP 地址")
                            .font(.system(size: 13, weight: .semibold))
                        
                        TextField("例如: 192.168.1.100 或 10.0.0.0", text: $destination)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13, design: .monospaced))
                    }
                    
                    // 路由类型
                    VStack(alignment: .leading, spacing: 6) {
                        Text("路由类型")
                            .font(.system(size: 13, weight: .semibold))
                        
                        Picker("", selection: $isSingleHost) {
                            Text("单个主机").tag(true)
                            Text("网段").tag(false)
                        }
                        .pickerStyle(.segmented)
                        
                        if !isSingleHost {
                            TextField("子网掩码，例: 255.255.255.0", text: $subnetMask)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 13, design: .monospaced))
                        }
                    }
                    
                    // 选择网络接口
                    VStack(alignment: .leading, spacing: 6) {
                        Text("通过哪个网络接口")
                            .font(.system(size: 13, weight: .semibold))
                        
                        if networkManager.interfaces.isEmpty {
                            Text("没有检测到可用的网络接口")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(networkManager.interfaces) { iface in
                                InterfacePickerRow(
                                    interface: iface,
                                    isSelected: selectedInterface?.name == iface.name,
                                    onSelect: { selectedInterface = iface }
                                )
                            }
                        }
                    }
                    
                    // 备注
                    VStack(alignment: .leading, spacing: 6) {
                        Text("备注 (可选)")
                            .font(.system(size: 13, weight: .semibold))
                        
                        TextField("例如: 公司内网", text: $note)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // 底部按钮
            HStack {
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("添加并应用") {
                    saveAndApply()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(destination.isEmpty || selectedInterface == nil)
            }
            .padding(20)
        }
        .frame(width: 480, height: 550)
        .onAppear {
            // 确保 Sheet 窗口能获得键盘焦点
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.last {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
    }
    
    private func saveAndApply() {
        guard let iface = selectedInterface else { return }
        
        let rule = RouteRule(
            destination: destination,
            subnetMask: isSingleHost ? "255.255.255.255" : subnetMask,
            interfaceName: iface.name,
            interfaceDisplayName: iface.displayName,
            isEnabled: true,
            note: note
        )
        
        onSave(rule)
        _ = networkManager.addRoute(rule)
        dismiss()
    }
}

// MARK: - Edit Route Rule Sheet

struct EditRouteRuleSheet: View {
    @EnvironmentObject var networkManager: NetworkManager
    @Environment(\.dismiss) var dismiss
    
    let rule: RouteRule
    let onSave: (RouteRule) -> Void
    
    @State private var destination: String
    @State private var subnetMask: String
    @State private var selectedInterface: NetworkInterface?
    @State private var note: String
    @State private var isSingleHost: Bool
    
    init(rule: RouteRule, onSave: @escaping (RouteRule) -> Void) {
        self.rule = rule
        self.onSave = onSave
        self._destination = State(initialValue: rule.destination)
        self._subnetMask = State(initialValue: rule.subnetMask)
        self._note = State(initialValue: rule.note)
        self._isSingleHost = State(initialValue: rule.subnetMask == "255.255.255.255")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("编辑路由规则")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("目标 IP 地址")
                            .font(.system(size: 13, weight: .semibold))
                        TextField("例如: 192.168.1.100", text: $destination)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13, design: .monospaced))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("路由类型")
                            .font(.system(size: 13, weight: .semibold))
                        Picker("", selection: $isSingleHost) {
                            Text("单个主机").tag(true)
                            Text("网段").tag(false)
                        }
                        .pickerStyle(.segmented)
                        
                        if !isSingleHost {
                            TextField("子网掩码", text: $subnetMask)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 13, design: .monospaced))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("通过哪个网络接口")
                            .font(.system(size: 13, weight: .semibold))
                        
                        ForEach(networkManager.interfaces) { iface in
                            InterfacePickerRow(
                                interface: iface,
                                isSelected: selectedInterface?.name == iface.name,
                                onSelect: { selectedInterface = iface }
                            )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("备注 (可选)")
                            .font(.system(size: 13, weight: .semibold))
                        TextField("备注", text: $note)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            HStack {
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("保存") {
                    saveRule()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(destination.isEmpty)
            }
            .padding(20)
        }
        .frame(width: 480, height: 550)
        .onAppear {
            selectedInterface = networkManager.interfaces.first(where: { $0.name == rule.interfaceName })
            // 确保 Sheet 窗口能获得键盘焦点
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.last {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
    }
    
    private func saveRule() {
        var updatedRule = rule
        updatedRule.destination = destination
        updatedRule.subnetMask = isSingleHost ? "255.255.255.255" : subnetMask
        updatedRule.interfaceName = selectedInterface?.name ?? rule.interfaceName
        updatedRule.interfaceDisplayName = selectedInterface?.displayName ?? rule.interfaceDisplayName
        updatedRule.note = note
        
        // 先删除旧路由
        _ = networkManager.removeRoute(rule)
        
        // 添加新路由
        if updatedRule.isEnabled {
            _ = networkManager.addRoute(updatedRule)
        }
        
        onSave(updatedRule)
        dismiss()
    }
}

// MARK: - Interface Picker Row

struct InterfacePickerRow: View {
    let interface: NetworkInterface
    let isSelected: Bool
    let onSelect: () -> Void
    
    var typeColor: Color {
        switch interface.type {
        case .wifi: return .cyan
        case .ethernet: return .green
        case .other: return .gray
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: interface.type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(typeColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(interface.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("\(interface.name) · \(interface.ipAddress) · 网关: \(interface.gateway)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(typeColor)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? typeColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? typeColor.opacity(0.4) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
