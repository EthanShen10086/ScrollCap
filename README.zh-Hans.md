# ScrollCap

[English](README.md) | **简体中文**

一款原生 SwiftUI 滚动长截图工具，支持 iOS、iPadOS 和 macOS。将可滚动的长内容捕获为一张拼接图片 —— 无需付费开发者账号。

## 功能特性

- **滚动截图**：录制滚动内容并自动拼接为一张长截图
- **跨平台**：iPhone、iPad、Mac 原生运行，自适应 UI
- **Liquid Glass 设计**：支持 Apple Liquid Glass 设计语言（iOS 26+ / macOS 26+），旧系统优雅降级
- **Vision 驱动拼接**：使用 Apple Vision 框架 (`VNTranslationalImageRegistrationRequest`) 实现像素级精确对齐
- **零第三方依赖**：完全基于 Apple 原生框架构建
- **图像编辑**：裁剪、标注，支持 PNG/JPEG/HEIC/PDF 格式导出
- **OCR 文字识别**：从截图中提取中英文文字
- **iCloud 同步**：跨设备截图历史云同步
- **Widget 小组件**：桌面/锁屏一键截图
- **多种支付方式**：App Store、Apple Pay、Stripe、微信支付、支付宝、PayPal
- **未成年模式**：隐藏支付、限制使用时长、简化界面
- **适老化模式**：大字体、大按钮、高对比度、减少动画

## 架构

```
ScrollCap/
├── App/                         # 应用层
│   ├── Shared/                  # 跨平台 SwiftUI 视图
│   ├── iOS/                     # iOS/iPadOS 专属视图
│   └── macOS/                   # macOS 专属视图（菜单栏、区域选择器）
├── BroadcastExtension/          # iOS ReplayKit 广播上传扩展
├── ScrollCapWidget/             # WidgetKit 小组件扩展
└── Packages/                    # 模块化 Swift 包
    ├── SharedModels/            # 跨模块共享数据模型
    ├── DesignSystem/            # Liquid Glass 适配、主题、自适应导航
    ├── CaptureKit/              # 平台抽象的捕获服务
    │   ├── CaptureKit/          # 共享协议
    │   ├── CaptureKitMac/       # macOS: ScreenCaptureKit 实现
    │   └── CaptureKitIOS/       # iOS: ReplayKit 实现
    ├── StitchingEngine/         # Vision 图像对齐与拼接
    └── ImageEditor/             # 裁剪、标注、导出工具
```

### 设计原则

- **Clean Architecture + MVVM** — 业务逻辑 100% 共享，UI 按平台适配
- **面向协议抽象** — `CaptureService` 协议统一 macOS/iOS 捕获接口
- **Swift Observation** — 现代 `@Observable` 状态管理
- **SwiftUI Environment 注入** — 零第三方依赖注入

### 平台捕获策略

| 平台 | 框架 | 方式 |
|------|------|------|
| macOS | ScreenCaptureKit | 基于区域的滚动帧捕获 |
| iOS/iPadOS | ReplayKit | 广播扩展屏幕录制 |
| 全平台 | Vision | `VNTranslationalImageRegistrationRequest` 拼接 |

## 系统要求

- **macOS 14.0+** / **iOS 17.0+**
- Xcode 16.0+（Swift 6.0）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（项目生成）

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/EthanShen10086/ScrollCap.git
cd ScrollCap
```

### 2. 一键配置（推荐）

```bash
bash setup.sh
```

此脚本会自动安装 XcodeGen、SwiftLint、SwiftFormat，配置 Git Hooks，生成并打开 Xcode 项目。

### 3. 手动配置

```bash
brew install xcodegen   # 如未安装
xcodegen generate
open ScrollCap.xcodeproj
```

- 选择 **ScrollCap-macOS** scheme 构建 Mac 版
- 选择 **ScrollCap-iOS** scheme 构建 iPhone/iPad 模拟器版
- 真机测试：在 **Signing > Team** 中选择你的 Personal Team（免费 Apple ID）

### 无开发者账号测试

- **模拟器**：开箱即用，无需账号
- **真机（侧载）**：
  1. 在 Xcode 中打开 Signing & Capabilities
  2. 选择 Personal Team（免费 Apple ID）
  3. 构建并运行到设备
  4. 在设备上：设置 > 通用 > VPN 与设备管理 > 信任证书
  5. 应用 7 天过期后需重新构建
- **macOS**：直接 Build & Run，无需特殊签名

## 代码质量

- **SwiftLint** + **SwiftFormat** — 代码风格自动检查
- **Git Hooks** — 提交前自动 lint，提交消息遵循 Conventional Commits
- **CI/CD** — GitHub Actions 自动构建和检查

## 技术栈

| 类别 | 技术 |
|------|------|
| 语言 | Swift 6 |
| UI 框架 | SwiftUI |
| 状态管理 | `@Observable` + SwiftUI Environment |
| macOS 截图 | ScreenCaptureKit |
| iOS 截图 | ReplayKit + Broadcast Extension |
| 图像对齐 | Vision Framework |
| 文字识别 | Vision Framework |
| 内购系统 | StoreKit 2 |
| 云同步 | iCloud Documents |
| 小组件 | WidgetKit + AppIntents |
| 项目生成 | XcodeGen |
| 第三方依赖 | **零** |

## 许可证

MIT License — 详见 [LICENSE](LICENSE)。
