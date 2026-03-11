import SwiftUI

struct ContentView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.07, blue: 0.14),
                    Color(red: 0.09, green: 0.11, blue: 0.22),
                    Color(red: 0.06, green: 0.07, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部标题栏
                headerView
                
                // 标签选择器
                tabSelector
                
                // 主内容区域
                Group {
                    switch selectedTab {
                    case 0:
                        InterfacesView()
                    case 1:
                        RouteRulesView()
                    case 2:
                        RouteTableView()
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 底部状态栏
                statusBar
            }
        }
        .preferredColorScheme(.dark)
        .alert("错误", isPresented: $networkManager.showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(networkManager.errorMessage)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "network")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.cyan, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("网络路由管理器")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Network Route Manager")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            // 接口数量指示器
            HStack(spacing: 16) {
                interfaceCountBadge(
                    icon: "wifi",
                    count: networkManager.interfaces.filter { $0.type == .wifi }.count,
                    color: .cyan
                )
                interfaceCountBadge(
                    icon: "cable.connector",
                    count: networkManager.interfaces.filter { $0.type == .ethernet }.count,
                    color: .green
                )
            }
            
            // 刷新按钮
            Button(action: {
                withAnimation(.spring(response: 0.4)) {
                    networkManager.refreshInterfaces()
                    networkManager.fetchCurrentRoutes()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .rotationEffect(.degrees(networkManager.isRefreshing ? 360 : 0))
                    .animation(networkManager.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: networkManager.isRefreshing)
            }
            .buttonStyle(.plain)
            .padding(8)
            .background(Color.white.opacity(0.06))
            .clipShape(Circle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.03))
    }
    
    private func interfaceCountBadge(icon: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 4) {
            tabButton("网络接口", icon: "antenna.radiowaves.left.and.right", tag: 0)
            tabButton("路由规则", icon: "arrow.triangle.branch", tag: 1)
            tabButton("路由表", icon: "tablecells", tag: 2)
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
    
    private func tabButton(_ title: String, icon: String, tag: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedTab = tag
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(selectedTab == tag ? .white : .white.opacity(0.5))
            .background(
                selectedTab == tag ?
                    LinearGradient(colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.3)], startPoint: .leading, endPoint: .trailing) :
                    LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Status Bar
    
    private var statusBar: some View {
        HStack {
            if !networkManager.statusMessage.isEmpty {
                Text(networkManager.statusMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .transition(.opacity)
            }
            
            Spacer()
            
            Text("路由规则: \(networkManager.routeRules.count) 条")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .animation(.easeInOut, value: networkManager.statusMessage)
    }
}
