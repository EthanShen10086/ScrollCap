# ScrollCap 需求与功能追踪文档

> 最后更新：2026-04-29

## 项目概述

ScrollCap 是一款跨平台滚动长截图应用，支持 macOS、iOS 和 iPadOS。使用 SwiftUI 构建，采用 Clean Architecture + MVVM 架构设计。

---

## 核心需求

| # | 需求 | 状态 | 说明 |
|---|------|------|------|
| 1 | 滚动长截图功能 | ✅ 已完成 | macOS 使用 ScreenCaptureKit 区域截屏，iOS 使用 ReplayKit Broadcast Extension |
| 2 | 多平台支持（iOS/iPadOS/macOS） | ✅ 已完成 | 通过 XcodeGen + 共享代码层实现，iOS 17+ / macOS 14+ |
| 3 | Apple Liquid Glass 设计适配 | ✅ 已完成 | Xcode 26+ SDK 自动启用 `.glassEffect()`，当前使用 `.ultraThinMaterial` 优雅降级 |
| 4 | 最新 SwiftUI 技术 | ✅ 已完成 | Swift 6、`@Observable`、`NavigationSplitView`、`async/await` Actor 模型 |
| 5 | 世界级架构设计 | ✅ 已完成 | Clean Architecture + MVVM、Protocol-Oriented、零第三方依赖、5 个模块化 SPM 包 |
| 6 | Monorepo 结构 | ✅ 已完成 | Local Swift Packages：SharedModels、DesignSystem、StitchingEngine、CaptureKit、ImageEditor |
| 7 | GitHub 托管 | ✅ 已完成 | https://github.com/EthanShen10086/ScrollCap |
| 8 | 免开发者账号可测试 | ✅ 已完成 | `CODE_SIGNING_ALLOWED=NO` 构建 + Personal Team 签名指南 |

---

## 功能清单

### 截图与捕获

| 功能 | 平台 | 状态 | 技术实现 |
|------|------|------|----------|
| 屏幕区域选择捕获 | macOS | ✅ 已完成 | ScreenCaptureKit + `SCContentFilter` |
| 全屏录制捕获 | iOS/iPadOS | ✅ 已完成 | ReplayKit + Broadcast Upload Extension |
| 实时帧预览 | 全平台 | ✅ 已完成 | `onPreviewUpdated` 回调 + SwiftUI Image |
| Vision 图像对齐拼接 | 全平台 | ✅ 已完成 | `VNTranslationalImageRegistrationRequest` |
| App Group 帧传递 | iOS | ✅ 已完成 | `SharedFrameReader` + UserDefaults 状态同步 |
| 全局快捷键 (⌘⇧6) | macOS | ✅ 已完成 | Carbon `RegisterEventHotKey` |
| 菜单栏快捷操作 | macOS | ✅ 已完成 | `MenuBarExtra` + `.menuBarExtraStyle(.window)` |

### 图像编辑

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| 图像裁剪 | ✅ 已完成 | `CropTool` - CoreGraphics `cropping(to:)` |
| 矩形标注 | ✅ 已完成 | `AnnotationRenderer` - CGContext 绘制 |
| 箭头标注 | ✅ 已完成 | `AnnotationRenderer` - CGContext 绘制 |
| 高亮标注 | ✅ 已完成 | `AnnotationRenderer` - 半透明矩形填充 |
| 多颜色选择 | ✅ 已完成 | 红/蓝/绿/黄/白/黑 6 色 |

### 导出与分享

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| PNG 导出 | ✅ 已完成 | ImageIO `CGImageDestination` |
| JPEG 导出（可调质量） | ✅ 已完成 | ImageIO + `kCGImageDestinationLossyCompressionQuality` |
| HEIC 导出 | ✅ 已完成 | ImageIO |
| PDF 导出 | ✅ 已完成 | `CGContext` PDF 绘制 |
| macOS NSSavePanel 保存 | ✅ 已完成 | `NSSavePanel` + `allowedContentTypes` |
| iOS ShareLink 分享 | ✅ 已完成 | SwiftUI `ShareLink` |

### 数据管理

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| 截图历史列表 | ✅ 已完成 | LazyVGrid + `ScreenshotCard` |
| 本地持久化存储 | ✅ 已完成 | `ScreenshotStore` Actor - 文件系统 + JSON Manifest |
| 截图详情查看 | ✅ 已完成 | `ScreenshotDetailView` + 元数据展示 |
| 截图删除 | ✅ 已完成 | Context Menu + `AppState.removeScreenshot` |

---

## 平台适配

### UI 适配

| 设备 | 布局方案 | 状态 |
|------|----------|------|
| macOS | NavigationSplitView 侧边栏 + 详情 | ✅ 已完成 |
| iPad | NavigationSplitView 侧边栏 + 详情 | ✅ 已完成 |
| iPhone | TabView + NavigationStack | ✅ 已完成 |

### 设计系统

| 特性 | 状态 | 说明 |
|------|------|------|
| Liquid Glass (iOS 26+/macOS 26+) | ✅ 已完成 | 编译时降级，Xcode 26 后自动启用 |
| Material 背景 | ✅ 已完成 | `.ultraThinMaterial` / `.thinMaterial` |
| 语义化颜色 | ✅ 已完成 | `.primary` / `.secondary` / `.tertiary` |
| 自适应调色板 | ✅ 已完成 | AccentColor / CardBackground / SurfaceElevated 均含深色变体 |
| 统一间距/圆角/排版系统 | ✅ 已完成 | `SCTheme` 枚举封装 |

---

## 国际化 (i18n)

| 语言 | 状态 | 覆盖范围 |
|------|------|----------|
| English (en) | ✅ 已完成 | 全部 UI 文案（120+ 条） |
| 简体中文 (zh-Hans) | ✅ 已完成 | 全部 UI 文案（120+ 条） |

**覆盖文件**：CaptureView、HistoryView、SettingsView、ContentView、ImageEditorView、ScreenshotDetailView、MenuBarView、MacCaptureView、IOSCaptureView、BroadcastSetupView、ScrollCapApp、AppState

---

## 深色模式

| 特性 | 状态 | 说明 |
|------|------|------|
| AccentColor 双模式 | ✅ 已完成 | Light: (0, 0.47, 0.98) / Dark: (0.26, 0.58, 1.0) |
| CardBackground 双模式 | ✅ 已完成 | Light: 黑色 6% / Dark: 白色 12% |
| SurfaceElevated 双模式 | ✅ 已完成 | 浅色/深色对应色值 |
| 语义色全覆盖 | ✅ 已完成 | 所有 UI 组件使用 SwiftUI 语义色 |
| Material 自适应 | ✅ 已完成 | `.ultraThinMaterial` 自动跟随系统外观 |

---

## 无障碍 (Accessibility)

| 特性 | 状态 | 说明 |
|------|------|------|
| VoiceOver 标签 | ✅ 已完成 | CaptureButton、StatusPill、截图卡片、编辑器工具、颜色选择器、元数据项 |
| VoiceOver 提示 | ✅ 已完成 | 按钮功能描述、截图尺寸信息 |
| 元素组合 | ✅ 已完成 | EmptyStateView、ScreenshotCard、元数据项使用 `.accessibilityElement(children: .combine)` |
| 装饰性图标隐藏 | ✅ 已完成 | `.accessibilityHidden(true)` 用于纯装饰图标 |
| 选中状态标注 | ✅ 已完成 | 编辑器工具和颜色选择器使用 `.isSelected` trait |
| Dynamic Type | ✅ 已完成 | 全部使用 SwiftUI 系统字体（自动支持） |
| Reduce Motion | ✅ 已完成 | iOS 录制指示器动画尊重 `accessibilityReduceMotion` |

---

## CI/CD

| 特性 | 状态 | 说明 |
|------|------|------|
| Swift Package 构建 | ✅ 已完成 | 5 个包全部 CI 构建 |
| Swift Package 测试 | ✅ 已完成 | SharedModels、StitchingEngine、ImageEditor |
| macOS Xcode 构建 | ✅ 已完成 | ScrollCap-macOS scheme |
| iOS Xcode 构建 | ✅ 已完成 | ScrollCap-iOS scheme (iPhone 16 Pro Simulator) |
| 并发控制 | ✅ 已完成 | 同一分支重复推送自动取消旧构建 |
| GitHub Actions | ✅ 已完成 | `macos-15` runner + Xcode 16 |

---

## 额外优化

| 特性 | 状态 | 说明 |
|------|------|------|
| Privacy Manifest | ✅ 已完成 | `PrivacyInfo.xcprivacy` 声明 API 使用 |
| Haptic Feedback | ✅ 已完成 | iOS 触觉反馈：捕获开始/完成/错误 |
| InfoPlist 本地化 | ✅ 已完成 | 应用名称和版权信息中英文 |
| Setup 自动化脚本 | ✅ 已完成 | `setup.sh` 自动配置 Xcode + 构建运行 |

---

## 架构设计

```
┌─────────────────────────────────────────┐
│            App Layer (SwiftUI)          │
│  ScrollCapApp → ContentView            │
│  CaptureView ←→ CaptureViewModel       │
│  HistoryView / SettingsView / Editor    │
├─────────────────────────────────────────┤
│          Platform Layer                 │
│  macOS: ScreenCaptureService            │
│  iOS:   ReplayKitCaptureService         │
│         BroadcastExtension              │
├─────────────────────────────────────────┤
│          Core Packages (SPM)            │
│  SharedModels │ DesignSystem            │
│  StitchingEngine │ CaptureKit           │
│  ImageEditor                            │
└─────────────────────────────────────────┘
```

---

## 技术栈

| 类别 | 技术 |
|------|------|
| 语言 | Swift 6 |
| UI 框架 | SwiftUI |
| 状态管理 | `@Observable` + SwiftUI Environment |
| 并发模型 | Swift Concurrency (async/await, Actor) |
| macOS 截图 | ScreenCaptureKit |
| iOS 截图 | ReplayKit + Broadcast Extension |
| 图像对齐 | Vision Framework (`VNTranslationalImageRegistrationRequest`) |
| 图像导出 | ImageIO |
| 项目生成 | XcodeGen |
| CI/CD | GitHub Actions |
| 第三方依赖 | **零** |

---

## 未来规划

| 功能 | 优先级 | 说明 |
|------|--------|------|
| 原生 Liquid Glass | 高 | 升级到 Xcode 26 后自动启用 |
| 自动滚动捕获 | 高 | 使用 Accessibility API 自动滚动页面 |
| 更多语言支持 | 中 | 日语、韩语、法语等 |
| Widget 支持 | 中 | 快捷操作 Widget + Live Activity |
| iCloud 同步 | 中 | 跨设备截图历史同步 |
| 文字识别 (OCR) | 低 | Vision Framework 文字提取 |
| 视频录制模式 | 低 | 滚动过程录制为视频 |
| App Icon 定制 | 低 | 当前使用默认图标，可设计专属 App Icon |
| TestFlight 分发 | 低 | 需要 Apple Developer 账号 |
