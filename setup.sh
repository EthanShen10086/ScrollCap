#!/bin/bash
# ScrollCap 一键设置脚本
# 用途：安装 Xcode 后运行此脚本，自动完成项目配置和构建

set -e

echo "╔══════════════════════════════════════════╗"
echo "║     ScrollCap - 一键设置与构建脚本       ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 检查 Xcode
if ! [ -d "/Applications/Xcode.app" ]; then
    echo "❌ 未检测到 Xcode。请先从 App Store 安装 Xcode。"
    echo "   运行: open 'macappstore://apps.apple.com/app/id497799835'"
    open 'macappstore://apps.apple.com/app/id497799835'
    exit 1
fi

echo "✅ 检测到 Xcode: $(/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -version | head -1)"

# 设置 xcode-select
echo "⚙️  设置 Xcode 为活跃开发工具..."
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# 接受许可协议
echo "⚙️  接受 Xcode 许可协议..."
sudo xcodebuild -license accept 2>/dev/null || true

# 安装额外组件
echo "⚙️  安装 Xcode 组件（如需要）..."
xcodebuild -runFirstLaunch 2>/dev/null || true

# 确认 XcodeGen
if ! command -v xcodegen &>/dev/null; then
    echo "⚙️  安装 XcodeGen..."
    HOMEBREW_NO_AUTO_UPDATE=1 brew install xcodegen
fi

# 项目根目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 安装 Git Hooks
echo "⚙️  安装 Git Hooks (SwiftLint + SwiftFormat + Conventional Commits)..."
bash scripts/install-hooks.sh

# 安装代码质量工具
if ! command -v swiftlint &>/dev/null || ! command -v swiftformat &>/dev/null; then
    echo "⚙️  安装 SwiftLint + SwiftFormat..."
    HOMEBREW_NO_AUTO_UPDATE=1 brew install swiftlint swiftformat
fi

# 生成 Xcode 项目
echo "⚙️  生成 Xcode 项目..."
xcodegen generate

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║            构建 ScrollCap                ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 构建 macOS 版本
echo "🔨 构建 ScrollCap-macOS..."
xcodebuild build \
    -project ScrollCap.xcodeproj \
    -scheme ScrollCap-macOS \
    -destination "platform=macOS" \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    ONLY_ACTIVE_ARCH=YES \
    2>&1 | tail -3

if [ $? -eq 0 ]; then
    echo "✅ macOS 构建成功！"
else
    echo "❌ macOS 构建失败"
    exit 1
fi

# 构建 iOS Simulator 版本
echo ""
echo "🔨 构建 ScrollCap-iOS (Simulator)..."
xcodebuild build \
    -project ScrollCap.xcodeproj \
    -scheme ScrollCap-iOS \
    -destination "platform=iOS Simulator,name=iPhone 16" \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    ONLY_ACTIVE_ARCH=YES \
    2>&1 | tail -3

if [ $? -eq 0 ]; then
    echo "✅ iOS Simulator 构建成功！"
else
    echo "⚠️  iOS Simulator 构建失败（可能需要下载 iOS Simulator runtime）"
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║            运行 ScrollCap                ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 找到构建产物并运行 macOS 版本
BUILD_DIR=$(xcodebuild -project ScrollCap.xcodeproj -scheme ScrollCap-macOS -showBuildSettings 2>/dev/null | grep "BUILT_PRODUCTS_DIR" | head -1 | awk '{print $3}')

if [ -d "$BUILD_DIR/ScrollCap-macOS.app" ]; then
    echo "🚀 启动 ScrollCap macOS..."
    open "$BUILD_DIR/ScrollCap-macOS.app"
    echo "✅ ScrollCap 已启动！"
elif [ -d "$BUILD_DIR/ScrollCap.app" ]; then
    echo "🚀 启动 ScrollCap macOS..."
    open "$BUILD_DIR/ScrollCap.app"
    echo "✅ ScrollCap 已启动！"
else
    echo "📂 打开 Xcode 项目（可手动 Build & Run）..."
    open ScrollCap.xcodeproj
fi

echo ""
echo "=========================================="
echo "完成！ScrollCap 项目已就绪。"
echo ""
echo "后续操作："
echo "  • 在 Xcode 中打开: open ScrollCap.xcodeproj"
echo "  • macOS: 选择 ScrollCap-macOS scheme → Run"
echo "  • iOS:   选择 ScrollCap-iOS scheme → 选择模拟器 → Run"
echo "  • 真机:  在 Signing 中设置 Personal Team"
echo "=========================================="
