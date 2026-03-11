import SwiftUI

struct InterfacesView: View {
    @EnvironmentObject var networkManager: NetworkManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if networkManager.interfaces.isEmpty {
                    emptyState
                } else {
                    ForEach(networkManager.interfaces) { iface in
                        InterfaceCard(interface: iface)
                    }
                }
            }
            .padding(24)
        }
        .background(Color.clear)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48, weight: .thin))
                .foregroundColor(.white.opacity(0.3))
            
            Text("未检测到活跃的网络接口")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            Text("请确保 Wi-Fi 已连接或已插入网线")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.3))
            
            Button(action: {
                networkManager.refreshInterfaces()
            }) {
                Label("刷新", systemImage: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

struct InterfaceCard: View {
    let interface: NetworkInterface
    @State private var isHovered = false
    
    var typeColor: Color {
        switch interface.type {
        case .wifi: return .cyan
        case .ethernet: return .green
        case .other: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 卡片头部
            HStack(spacing: 14) {
                // 接口图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [typeColor.opacity(0.3), typeColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: interface.type.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(typeColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(interface.displayName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(interface.name)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    
                    Text(interface.type.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(typeColor.opacity(0.8))
                }
                
                Spacer()
                
                // 活跃状态指示
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .shadow(color: .green.opacity(0.6), radius: 4)
                    
                    Text("活跃")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .clipShape(Capsule())
            }
            .padding(16)
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // 详细信息网格
            HStack(spacing: 0) {
                infoItem(label: "IP 地址", value: interface.ipAddress, icon: "number")
                
                Divider()
                    .background(Color.white.opacity(0.08))
                    .frame(height: 40)
                
                infoItem(label: "子网掩码", value: interface.subnetMask, icon: "square.grid.3x3")
                
                Divider()
                    .background(Color.white.opacity(0.08))
                    .frame(height: 40)
                
                infoItem(label: "网关", value: interface.gateway, icon: "arrow.triangle.branch")
                
                Divider()
                    .background(Color.white.opacity(0.08))
                    .frame(height: 40)
                
                infoItem(label: "MAC 地址", value: interface.macAddress, icon: "barcode")
            }
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isHovered ? 0.08 : 0.05))
                .shadow(color: typeColor.opacity(isHovered ? 0.15 : 0), radius: 20, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [typeColor.opacity(isHovered ? 0.3 : 0.1), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private func infoItem(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
            }
            
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}
