#!/bin/bash
set -e

APP_NAME="网络分配"
BUILD_DIR=".build/release"
APP_DIR="${APP_NAME}.app"

# 1. 以 Release 模式编译
echo "正在编译 Release 版本..."
swift build -c release

# 2. 创建 macOS .app 目录结构
echo "正在创建 App 包..."
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# 3. 复制可执行文件
cp "${BUILD_DIR}/NetworkRouter" "${APP_DIR}/Contents/MacOS/${APP_NAME}"

# 4. 复制图标文件
cp AppIcon.icns "${APP_DIR}/Contents/Resources/AppIcon.icns"

# 5. 生成 Info.plist
cat > "${APP_DIR}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.wzj.NetworkRouter</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
EOF

echo "✅ 打包完成！双击可运行应用: ${APP_DIR}"
