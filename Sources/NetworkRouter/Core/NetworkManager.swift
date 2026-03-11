import Foundation
import Combine

// MARK: - NetworkManager

/// 核心网络管理器
/// 负责检测接口、管理路由规则、执行系统命令
class NetworkManager: ObservableObject {
    @Published var interfaces: [NetworkInterface] = []
    @Published var routeRules: [RouteRule] = []
    @Published var currentRoutes: [String] = []
    @Published var isRefreshing = false
    @Published var statusMessage = ""
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let rulesStorageKey = "NetworkRouterRules"
    private var refreshTimer: Timer?
    
    init() {
        loadRules()
        refreshInterfaces()
        fetchCurrentRoutes()
        
        // 启动时同步系统路由真实状态
        syncRulesWithSystem()
        
        // 每30秒自动刷新网络状态
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.refreshInterfaces()
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - 公开接口
    
    /// 手动刷新网络接口列表
    func refreshInterfaces() {
        isRefreshing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let detectedInterfaces = self?.detectInterfaces() ?? []
            
            DispatchQueue.main.async {
                self?.interfaces = detectedInterfaces
                self?.isRefreshing = false
            }
        }
    }
    
    /// 获取系统当前路由表
    func fetchCurrentRoutes() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let output = self?.runCommand("/usr/sbin/netstat", arguments: ["-rn"]) ?? ""
            let lines = output.components(separatedBy: "\n")
                .filter { !$0.isEmpty && !$0.hasPrefix("Routing") && !$0.hasPrefix("Destination") && !$0.hasPrefix("Internet") }
            
            DispatchQueue.main.async {
                self?.currentRoutes = lines
            }
        }
    }
    
    /// 添加单条路由规则到系统
    func addRoute(_ rule: RouteRule) -> Bool {
        guard !rule.destination.isEmpty else {
            showErrorMessage("目标 IP 不能为空")
            return false
        }
        
        guard let iface = interfaces.first(where: { $0.name == rule.interfaceName }) else {
            showErrorMessage("请选择一个有效的网络接口")
            return false
        }
        
        let gateway = iface.gateway
        var args: [String]
        
        if rule.subnetMask == "255.255.255.255" {
            args = ["-n", "add", "-host", rule.destination, gateway]
        } else {
            args = ["-n", "add", "-net", rule.destination, "-netmask", rule.subnetMask, gateway]
        }
        
        let script = """
        do shell script "/sbin/route \(args.joined(separator: " "))" with administrator privileges
        """
        
        let output = runOsascript(script)
        
        if output.contains("add net") || output.contains("add host") || output.isEmpty {
            statusMessage = "✅ 路由规则已添加: \(rule.destination) → \(iface.displayName)"
            fetchCurrentRoutes()
            return true
        } else {
            showErrorMessage("添加路由失败: \(output)")
            return false
        }
    }
    
    /// 从系统删除路由规则
    func removeRoute(_ rule: RouteRule) -> Bool {
        var args: [String]
        
        if rule.subnetMask == "255.255.255.255" {
            args = ["-n", "delete", "-host", rule.destination]
        } else {
            args = ["-n", "delete", "-net", rule.destination, "-netmask", rule.subnetMask]
        }
        
        let script = """
        do shell script "/sbin/route \(args.joined(separator: " "))" with administrator privileges
        """
        
        let output = runOsascript(script)
        
        if output.contains("delete") || output.isEmpty {
            statusMessage = "🗑 路由规则已删除: \(rule.destination)"
            fetchCurrentRoutes()
            return true
        } else {
            showErrorMessage("删除路由失败: \(output)")
            return false
        }
    }
    
    /// 批量应用所有启用的规则
    func applyAllRules() {
        let rulesToApply = routeRules.filter { $0.isEnabled }
        guard !rulesToApply.isEmpty else { return }
        
        batchAddRoutes(rulesToApply)
    }
    
    /// 核心批量添加方法（只验证一次管理员密码）
    private func batchAddRoutes(_ rules: [RouteRule]) {
        var shellCommands: [String] = []
        var validRules: [RouteRule] = []
        
        for rule in rules {
            guard !rule.destination.isEmpty else { continue }
            guard let iface = interfaces.first(where: { $0.name == rule.interfaceName }) else { continue }
            
            let gateway = iface.gateway
            if rule.subnetMask == "255.255.255.255" {
                shellCommands.append("/sbin/route -n add -host \(rule.destination) \(gateway)")
            } else {
                shellCommands.append("/sbin/route -n add -net \(rule.destination) -netmask \(rule.subnetMask) \(gateway)")
            }
            validRules.append(rule)
        }
        
        guard !shellCommands.isEmpty else { return }
        
        // 用分号拼接所有命令，以确保只弹一次密码输入框
        let combinedCommand = shellCommands.joined(separator: "; ")
        let script = """
        do shell script "\(combinedCommand)" with administrator privileges
        """
        
        let output = runOsascript(script)
        
        // 简单分析结果，这里主要是为了确保执行完成
        if output.contains("add net") || output.contains("add host") || output.isEmpty {
            statusMessage = "✅ 批量应用完成: 成功 \(validRules.count) 条"
        } else {
            statusMessage = "⚠️ 批量应用完成，部分可能失败: \(output)"
        }
        
        fetchCurrentRoutes()
    }
    
    /// 清除所有已应用的路由
    func clearAllRoutes() {
        var count = 0
        for rule in routeRules where rule.isEnabled {
            if removeRoute(rule) {
                count += 1
            }
        }
        statusMessage = "🗑 已清除 \(count) 条路由规则"
    }
    
    // MARK: - 规则持久化与同步
    
    func saveRules() {
        if let data = try? JSONEncoder().encode(routeRules) {
            UserDefaults.standard.set(data, forKey: rulesStorageKey)
        }
    }
    
    func loadRules() {
        if let data = UserDefaults.standard.data(forKey: rulesStorageKey),
           let rules = try? JSONDecoder().decode([RouteRule].self, from: data) {
            routeRules = rules
        } else {
            // 数据迁移：如果用户之前是通过 swift run 运行的（没有 bundle ID），旧规则保存在名为 NetworkRouter 的域中
            // 迁移这些规则到当前 .app 对应的标准域 (com.wzj.NetworkRouter) 中
            if let oldData = UserDefaults(suiteName: "NetworkRouter")?.data(forKey: rulesStorageKey),
               let rules = try? JSONDecoder().decode([RouteRule].self, from: oldData) {
                routeRules = rules
                saveRules() // 保存到新位置
            }
        }
    }
    
    /// 将配置的路由规则与真实的系统路由表比对，自动修正开关状态
    func syncRulesWithSystem() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let output = self.runCommand("/usr/sbin/netstat", arguments: ["-rn"])
            let lines = output.components(separatedBy: "\n")
            
            // 获取系统里所有的 Destination 项
            var systemDestinations = Set<String>()
            for line in lines {
                let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if let dest = parts.first, dest != "Destination", dest != "Routing", dest != "Internet:" {
                    systemDestinations.insert(dest)
                }
            }
            
            DispatchQueue.main.async {
                var updated = false
                var missingRulesToApply: [RouteRule] = []
                
                for i in 0..<self.routeRules.count {
                    let dest = self.routeRules[i].destination
                    // 检查此 IP 是否真实存在于路由表
                    let isActuallyInSystem = systemDestinations.contains(dest)
                    
                    if self.routeRules[i].isEnabled && !isActuallyInSystem {
                        // 设为启用，但系统里没有（可能是重启后丢失了），需要自动补全
                        missingRulesToApply.append(self.routeRules[i])
                    } else if !self.routeRules[i].isEnabled && isActuallyInSystem {
                        // 设为关闭，但系统里竟然有（可能在命令行里手加的），同步状态为开启
                        self.routeRules[i].isEnabled = true
                        updated = true
                    }
                }
                
                if updated {
                    self.saveRules()
                }
                
                // 立即应用那些系统里丢失的规则
                if !missingRulesToApply.isEmpty {
                    self.batchAddRoutes(missingRulesToApply)
                }
            }
        }
    }
    
    // MARK: - 接口检测 (私有)
    
    private func detectInterfaces() -> [NetworkInterface] {
        var interfaces: [NetworkInterface] = []
        
        let ifconfigOutput = runCommand("/sbin/ifconfig", arguments: ["-a"])
        let portMapping = getHardwarePortMapping()
        let defaultGateway = getDefaultGateway()
        let interfaceBlocks = parseIfconfigOutput(ifconfigOutput)
        
        for (ifName, info) in interfaceBlocks {
            guard ifName.hasPrefix("en") else { continue }
            guard let ipAddress = info["inet"], !ipAddress.isEmpty else { continue }
            
            let isUp = info["status"] == "active" || (info["flags"]?.contains("UP") ?? false)
            guard isUp else { continue }
            
            let (displayName, ifType) = getInterfaceTypeAndName(ifName: ifName, portMapping: portMapping)
            let gateway = getGatewayForInterface(ifName) ?? defaultGateway
            let macAddr = info["ether"] ?? "N/A"
            let mask = info["netmask"] ?? "N/A"
            
            interfaces.append(NetworkInterface(
                name: ifName,
                displayName: displayName,
                type: ifType,
                ipAddress: ipAddress,
                subnetMask: mask,
                gateway: gateway,
                isActive: true,
                macAddress: macAddr
            ))
        }
        
        // 排序: WiFi → 以太网 → 其他
        interfaces.sort { a, b in
            if a.type == .wifi && b.type != .wifi { return true }
            if a.type == .ethernet && b.type == .other { return true }
            return false
        }
        
        return interfaces
    }
    
    private func getHardwarePortMapping() -> [String: (name: String, type: InterfaceType)] {
        let output = runCommand("/usr/sbin/networksetup", arguments: ["-listallhardwareports"])
        var mapping: [String: (name: String, type: InterfaceType)] = [:]
        
        let lines = output.components(separatedBy: "\n")
        var currentName = ""
        var currentType: InterfaceType = .other
        
        for line in lines {
            if line.hasPrefix("Hardware Port:") {
                let portName = line.replacingOccurrences(of: "Hardware Port: ", with: "").trimmingCharacters(in: .whitespaces)
                currentName = portName
                if portName.lowercased().contains("wi-fi") || portName.lowercased().contains("wifi") {
                    currentType = .wifi
                } else if portName.lowercased().contains("ethernet") || portName.lowercased().contains("thunderbolt") || portName.lowercased().contains("usb") {
                    currentType = .ethernet
                } else {
                    currentType = .other
                }
            } else if line.hasPrefix("Device:") {
                let device = line.replacingOccurrences(of: "Device: ", with: "").trimmingCharacters(in: .whitespaces)
                mapping[device] = (name: currentName, type: currentType)
            }
        }
        
        return mapping
    }
    
    private func parseIfconfigOutput(_ output: String) -> [String: [String: String]] {
        var result: [String: [String: String]] = [:]
        var currentInterface = ""
        var currentInfo: [String: String] = [:]
        
        for line in output.components(separatedBy: "\n") {
            if !line.hasPrefix("\t") && !line.hasPrefix(" ") && line.contains(":") {
                if !currentInterface.isEmpty {
                    result[currentInterface] = currentInfo
                }
                currentInterface = String(line.prefix(while: { $0 != ":" }))
                currentInfo = [:]
                if line.contains("flags=") {
                    currentInfo["flags"] = line
                }
            } else {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("inet ") {
                    let parts = trimmed.components(separatedBy: " ")
                    if parts.count >= 2 { currentInfo["inet"] = parts[1] }
                    if let maskIndex = parts.firstIndex(of: "netmask"), maskIndex + 1 < parts.count {
                        currentInfo["netmask"] = hexToSubnetMask(parts[maskIndex + 1])
                    }
                } else if trimmed.hasPrefix("ether ") {
                    let parts = trimmed.components(separatedBy: " ")
                    if parts.count >= 2 { currentInfo["ether"] = parts[1] }
                } else if trimmed.hasPrefix("status:") {
                    currentInfo["status"] = trimmed.replacingOccurrences(of: "status: ", with: "")
                }
            }
        }
        
        if !currentInterface.isEmpty {
            result[currentInterface] = currentInfo
        }
        
        return result
    }
    
    private func hexToSubnetMask(_ hex: String) -> String {
        let cleanHex = hex.replacingOccurrences(of: "0x", with: "")
        guard cleanHex.count == 8 else { return hex }
        
        var parts: [String] = []
        var index = cleanHex.startIndex
        for _ in 0..<4 {
            let end = cleanHex.index(index, offsetBy: 2)
            if let byte = UInt8(String(cleanHex[index..<end]), radix: 16) {
                parts.append("\(byte)")
            }
            index = end
        }
        
        return parts.joined(separator: ".")
    }
    
    private func getInterfaceTypeAndName(ifName: String, portMapping: [String: (name: String, type: InterfaceType)]) -> (String, InterfaceType) {
        if let mapped = portMapping[ifName] {
            return (mapped.name, mapped.type)
        }
        return ifName == "en0" ? ("Wi-Fi", .wifi) : (ifName == "en1" ? ("以太网", .ethernet) : (ifName, .other))
    }
    
    private func getDefaultGateway() -> String {
        let output = runCommand("/usr/sbin/netstat", arguments: ["-rn"])
        for line in output.components(separatedBy: "\n") {
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 2 && parts[0] == "default" { return parts[1] }
        }
        return "N/A"
    }
    
    private func getGatewayForInterface(_ ifName: String) -> String? {
        let output = runCommand("/usr/sbin/netstat", arguments: ["-rn"])
        for line in output.components(separatedBy: "\n") {
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 4 && parts[0] == "default" && parts[3] == ifName { return parts[1] }
        }
        return nil
    }
    
    // MARK: - 命令执行工具

    func runCommand(_ command: String, arguments: [String] = []) -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    func runOsascript(_ script: String) -> String {
        let process = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            return output.isEmpty ? error : output
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    private func showErrorMessage(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
}
