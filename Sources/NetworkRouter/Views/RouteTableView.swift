import SwiftUI

struct RouteTableView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @State private var searchText = ""
    @State private var filterInterface = "全部"
    
    var filteredRoutes: [String] {
        var routes = networkManager.currentRoutes
        
        if !searchText.isEmpty {
            routes = routes.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
        
        if filterInterface != "全部" {
            routes = routes.filter { $0.contains(filterInterface) }
        }
        
        return routes
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack(spacing: 12) {
                // 搜索框
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    TextField("搜索路由...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(maxWidth: 280)
                
                // 接口过滤
                Picker("接口", selection: $filterInterface) {
                    Text("全部").tag("全部")
                    ForEach(networkManager.interfaces) { iface in
                        Text(iface.displayName).tag(iface.name)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                
                Spacer()
                
                // 刷新按钮
                Button(action: {
                    networkManager.fetchCurrentRoutes()
                }) {
                    Label("刷新路由表", systemImage: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(GlowButtonStyle(color: .cyan))
                
                // 条目数
                Text("\(filteredRoutes.count) 条路由")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.03))
            
            // 表头
            HStack(spacing: 0) {
                tableHeader("目标地址", width: 180)
                tableHeader("网关", width: 180)
                tableHeader("标志", width: 80)
                tableHeader("引用", width: 60)
                tableHeader("使用", width: 60)
                tableHeader("接口", width: 80)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.04))
            
            // 路由列表
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredRoutes.enumerated()), id: \.offset) { index, route in
                        RouteRow(route: route, index: index)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private func tableHeader(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white.opacity(0.7))
            .textCase(.uppercase)
            .frame(width: width, alignment: .leading)
    }
}

struct RouteRow: View {
    let route: String
    let index: Int
    @State private var isHovered = false
    
    var parts: [String] {
        route.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    }
    
    var interfaceColor: Color {
        guard parts.count > 3 else { return .gray }
        let ifName = parts.last ?? ""
        if ifName.contains("en0") { return .cyan }
        if ifName.contains("en") { return .green }
        return .gray
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 目标地址
            Text(parts.count > 0 ? parts[0] : "-")
                .frame(width: 180, alignment: .leading)
            
            // 网关
            Text(parts.count > 1 ? parts[1] : "-")
                .frame(width: 180, alignment: .leading)
            
            // 标志
            Text(parts.count > 2 ? parts[2] : "-")
                .frame(width: 80, alignment: .leading)
                .foregroundColor(.cyan.opacity(0.9))
            
            // 引用计数
            Text(parts.count > 3 ? parts[3] : "-")
                .frame(width: 60, alignment: .leading)
            
            // 使用次数
            Text(parts.count > 4 ? parts[4] : "-")
                .frame(width: 60, alignment: .leading)
            
            // 接口名
            if parts.count > 5 {
                Text(parts[5])
                    .foregroundColor(interfaceColor)
                    .fontWeight(.semibold)
                    .frame(width: 80, alignment: .leading)
            } else if parts.count > 3 {
                Text(parts.last ?? "-")
                    .foregroundColor(interfaceColor)
                    .fontWeight(.semibold)
                    .frame(width: 80, alignment: .leading)
            }
            
            Spacer()
        }
        .font(.system(size: 11, weight: .regular, design: .monospaced))
        .foregroundColor(.white.opacity(0.9))
        .padding(.vertical, 6)
        .padding(.horizontal, 0)
        .background(
            index % 2 == 0 ? Color.clear : Color.white.opacity(0.02)
        )
        .background(isHovered ? Color.white.opacity(0.04) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
