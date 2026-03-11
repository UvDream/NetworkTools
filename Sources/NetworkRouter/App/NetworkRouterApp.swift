import SwiftUI
import AppKit

/// 应用代理，确保通过 swift run 启动时也能正确激活为前台应用
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置为常规应用（显示 Dock 图标，接收键盘事件）
        NSApp.setActivationPolicy(.regular)
        // 激活为前台应用，确保窗口和文本框能获得键盘焦点
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // 确保主窗口成为 key window
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
}

@main
struct NetworkRouterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var networkManager = NetworkManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(networkManager)
                .frame(minWidth: 900, minHeight: 650)
                .onAppear {
                    // 延迟一帧确保窗口已创建后再激活
                    DispatchQueue.main.async {
                        NSApp.activate(ignoringOtherApps: true)
                        NSApp.windows.first?.makeKeyAndOrderFront(nil)
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1000, height: 700)
    }
}
