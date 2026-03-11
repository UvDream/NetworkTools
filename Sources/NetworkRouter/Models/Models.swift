import Foundation

// MARK: - 网络接口类型

/// 网络接口类型枚举
enum InterfaceType: String, Codable, CaseIterable {
    case wifi = "Wi-Fi"
    case ethernet = "以太网"
    case other = "其他"
    
    var icon: String {
        switch self {
        case .wifi: return "wifi"
        case .ethernet: return "cable.connector"
        case .other: return "network"
        }
    }
    
    var color: String {
        switch self {
        case .wifi: return "blue"
        case .ethernet: return "green"
        case .other: return "gray"
        }
    }
}

// MARK: - 网络接口信息

/// 描述一个物理网络接口的完整信息
struct NetworkInterface: Identifiable, Hashable {
    let id = UUID()
    let name: String           // 系统接口名, e.g., en0, en1
    let displayName: String    // 用户可读名, e.g., Wi-Fi, Ethernet
    let type: InterfaceType
    let ipAddress: String
    let subnetMask: String
    let gateway: String
    let isActive: Bool
    let macAddress: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: NetworkInterface, rhs: NetworkInterface) -> Bool {
        lhs.name == rhs.name
    }
}

// MARK: - IP 路由规则

/// 用户定义的路由规则，可持久化
struct RouteRule: Identifiable, Codable, Hashable {
    let id: UUID
    var destination: String          // 目标 IP 或网段
    var subnetMask: String           // 子网掩码 (255.255.255.255 = 单主机)
    var interfaceName: String        // 使用的网络接口系统名
    var interfaceDisplayName: String // 接口显示名
    var isEnabled: Bool
    var note: String                 // 用户备注
    
    init(
        destination: String = "",
        subnetMask: String = "255.255.255.255",
        interfaceName: String = "",
        interfaceDisplayName: String = "",
        isEnabled: Bool = true,
        note: String = ""
    ) {
        self.id = UUID()
        self.destination = destination
        self.subnetMask = subnetMask
        self.interfaceName = interfaceName
        self.interfaceDisplayName = interfaceDisplayName
        self.isEnabled = isEnabled
        self.note = note
    }
}
