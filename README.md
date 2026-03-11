# NetworkRouter (网络分配)

<p align="center">
  <img src="Sources/NetworkRouter/Resources/Assets.xcassets/AppIcon.appiconset/icon_256.png" alt="App Icon" width="128" />
</p>

**NetworkRouter (网络分配)** 是一款基于 macOS 和 SwiftUI 开发的极简、高效的网络路由配置工具。

在日常开发和办公中，我们经常会遇到**“双网卡难题”**：同时插着内网网线和外网 Wi-Fi，却发现内外网流量冲突，无法同时访问。如果你厌倦了每次打开终端敲击繁琐的 `route add` 命令，这款工具正是为你准备的。它可以可视化地读取系统所有网络接口，并允许你指定特定 IP / 网段 强行通过特定网卡（例如：让公司内网 IP 走有线网卡，让其它 IP 走 Wi-Fi）。

---

## ✨ 核心特性

- 🌐 **可视化网络面板**：自动检测所有在线的网络硬件接口（Wi-Fi、以太网、雷雳转接等），并直接展示它们的 IP 地址、子网掩码、独立网关和 MAC 地址。
- 🚥 **智能路由策略**：支持针对“单一主机 (Host)”或“整个网段 (Net/Subnet)”制定流量分发规则。
- 💾 **自动持久化与修复**：你在应用中勾选开启的规则会永久保存。重启电脑可能会导致系统路由表被清空，但你只需重新打开本应用，它会自动核对系统真实状态，并一键无感（或仅需验证1次指纹）补齐所有缺失的路由规则！
- 🔍 **活体路由表**：内置活体 `netstat` 路由表查看器，替代终端，实时支持按网卡接口过滤和全文搜索。
- 🎨 **极客美学**：全局暗黑系开发者主题（Dark Mode），发光霓虹组件，不占用系统顶部导航胶囊。

---

## 🚀 编译与安装

**环境要求**：
- macOS 14.0 (Sonoma) 及以上版本
- Swift 5.9+ 

**快速打包 `.app` 应用程序**：
项目根目录提供了一键打包脚本，执行后会自动编译 Release 版本并生成 macOS 专属的 `.app` 应用程序包并嵌入应用图标。

```bash
# 给予脚本执行权限
chmod +x build_app.sh

# 执行一键打包
./build_app.sh
```
执行完毕后，双击当前目录生成的 `网络分配.app` 即可享受！

---

## 🛠 项目架构说明

本项目采用了纯原生的 **SwiftUI + SwiftPM** 分层架构模式，不依赖任何第三方库，结构极其清晰，非常适合用来学习 macOS Native 桌面开发和 Shell 桥接：

```text
WebTools (Project Root)
├── Package.swift               # Swift 包配置 (最低支持 macOS 14)
├── build_app.sh                # macOS App 一键打包聚合脚本
└── Sources/
    └── NetworkRouter/
        ├── App/
        │   └── NetworkRouterApp.swift # App 生命周期、窗口前台激活代理
        ├── Core/
        │   └── NetworkManager.swift   # 核心引擎 (封装 ifconfig/route/netstat 命令行与持久化控制)
        ├── Models/
        │   └── Models.swift           # 数据模型层 (InterfaceType, Rule, Network等)
        ├── Styles/
        │   └── Styles.swift           # 视图装饰器 (霓虹按钮按压效果与发光主题)
        ├── Views/
        │   ├── ContentView.swift      # 主 Container (Tab/Group)
        │   ├── InterfacesView.swift   # 网卡信息探测大屏
        │   ├── RouteRulesView.swift   # 规则编辑、增删查页面
        │   └── RouteTableView.swift   # 系统底层真实路由表查看面板
        └── Resources/                 # 素材包 (AppIcon)
```

---

## 💡 如何使用？

1. **查看可用网卡**：在第一个 Tab 中，可以确认你现在的插入状态（确保 Wi-Fi 和有线的网关均已获取成功）。
2. **分配规则**：
   - 切换到第二个 Tab **“路由规则”**，点击添加。
   - 输入目标 IP（比如你的公司服务器 `10.0.0.0`），选择网段掩码。
   - 在下方选择“通过有线以太网”通行 👇，点击保存并应用。
3. **系统鉴权**：由于底层是直接调用 `/sbin/route` 控制系统内核网络栈，**系统会提示你输入开机密码或触控 ID 指纹进行鉴权**（这是 macOS 安全机制的正常现象，只会弹窗一次）。
4. **验证成果**：成功列表处亮起绿灯。此时你在浏览器或终端访问该 IP，流量就会严格通过你选定的网卡出去了！

---

## ⚠️ 注意事项与开源协定

- **管理员权限**：更改网络路由表（Routing Table）是一个**高危 / 系统级操作**，所以每次添加/删除规则或者批量应用时，macOS 系统必然会弹出管理员授权框。这是应用工作的基础逻辑。
- **睡眠 / 重启易失**：当你断网或重启 Mac 后，OS 会重置底层路由器网关。这时你的物理网络变化，底层路由会消失。**但是：**你只需要重新打开咱们的《网络分配》App，它会机智地察觉系统里“少了”你的规则，只要你点应用，它又能快速复原。
- 本项目遵循 **MIT 协议** 开放源代码。欢迎提 PR 或将其作为你下一个 macOS 效率工具的参考模板。

> *"让网络流量，如你所愿地流向正确的管道。"*
