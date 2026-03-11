import SwiftUI

// MARK: - 发光按钮样式

/// 带有发光边框效果的自定义按钮样式
struct GlowButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? color : .white.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(configuration.isPressed ? 0.3 : 0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 接口类型颜色扩展

extension InterfaceType {
    /// SwiftUI 颜色表示
    var swiftUIColor: Color {
        switch self {
        case .wifi: return .cyan
        case .ethernet: return .green
        case .other: return .gray
        }
    }
}
