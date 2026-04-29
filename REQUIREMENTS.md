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
| 自动滚动捕获 | iOS | ✅ 已完成 | `AutoScrollService` actor + `UIScrollView.setContentOffset` |

### 图像编辑

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| 图像裁剪 | ✅ 已完成 | `CropTool` - CoreGraphics `cropping(to:)` |
| 矩形标注 | ✅ 已完成 | `AnnotationRenderer` - CGContext 绘制 |
| 箭头标注 | ✅ 已完成 | `AnnotationRenderer` - CGContext 绘制 |
| 高亮标注 | ✅ 已完成 | `AnnotationRenderer` - 半透明矩形填充 |
| 多颜色选择 | ✅ 已完成 | 红/蓝/绿/黄/白/黑 6 色 |

### OCR 文字识别

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| 文字识别 | ✅ 已完成 | Vision `VNRecognizeTextRequest` + `.accurate` 级别 |
| 中英文支持 | ✅ 已完成 | `recognitionLanguages = ["zh-Hans", "en-US"]` |
| 全文提取 | ✅ 已完成 | `OCRService.recognizeFullText` |
| 一键复制 | ✅ 已完成 | NSPasteboard (macOS) / UIPasteboard (iOS) |
| UI 集成 | ✅ 已完成 | ScreenshotDetailView toolbar OCR 按钮 + 全屏 sheet |

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
| 截图历史列表 | ✅ 已完成 | LazyVGrid + `HistoryScreenshotCard` |
| 本地持久化存储 | ✅ 已完成 | `ScreenshotStore` Actor - 文件系统 + JSON Manifest |
| 截图详情查看 | ✅ 已完成 | `ScreenshotDetailView` + 元数据展示 |
| 截图删除 | ✅ 已完成 | Context Menu + `AppState.removeScreenshot` |
| iCloud 云同步 | ✅ 已完成 | `ICloudSyncManager` + `NSMetadataQuery` + `NSFileCoordinator` |

---

## Widget 快捷操作

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| 桌面 Widget | ✅ 已完成 | `.systemSmall` - 品牌图标 + Quick Capture 按钮 |
| 锁屏 Widget | ✅ 已完成 | `.accessoryRectangular` - 一键截图 |
| 圆形 Widget | ✅ 已完成 | `.accessoryCircular` - 图标快捷方式 |
| Deep Link | ✅ 已完成 | `scrollcap://capture` + `onOpenURL` 处理 |
| App Intent | ✅ 已完成 | `QuickCaptureIntent` 打开应用并触发截图 |

---

## 可观测性 / 分析埋点

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| 结构化日志 | ✅ 已完成 | `SCLogger` - OSLog 分类日志 (capture/stitch/export/sync/payment/ocr) |
| 崩溃报告 | ✅ 已完成 | `CrashReporter` - NSSetUncaughtExceptionHandler + signal handler |
| 事件埋点 | ✅ 已完成 | `AnalyticsManager` - JSONL 持久化事件流 |
| 设备信息采集 | ✅ 已完成 | `DeviceInfo` - OS 版本/应用版本/设备型号 |
| CaptureViewModel 集成 | ✅ 已完成 | startCapture/stopCapture/cancelCapture 事件追踪 |

---

## 支付系统 (Freemium)

### StoreKit 2 (Apple 内购)

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| 产品加载 | ✅ 已完成 | `StoreManager` - `Product.products` / 按价格排序 |
| 月度/年度/终身订阅 | ✅ 已完成 | 3 个产品 ID: monthly / yearly / lifetime |
| 购买流程 | ✅ 已完成 | `StoreManager.purchase` + `VerificationResult` 交易验证 |
| 恢复购买 | ✅ 已完成 | `Transaction.currentEntitlements` 遍历 |
| 订阅状态管理 | ✅ 已完成 | `SubscriptionInfo` + `Product.SubscriptionInfo.status` |
| 自动续费检测 | ✅ 已完成 | `RenewalState` 检查 (subscribed/inGracePeriod/expired/revoked) |
| 管理订阅跳转 | ✅ 已完成 | `AppStore.showManageSubscriptions` (iOS) / URL (macOS) |
| 交易监听 | ✅ 已完成 | `Transaction.updates` 后台监听 + 自动刷新 |
| Pro 功能门控 | ✅ 已完成 | `ProFeatureGate` ViewModifier + 模糊遮罩 |
| StoreKit 测试配置 | ✅ 已完成 | `Products.storekit` 含 introductory offer |

### Apple Pay (PassKit 原生)

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| 可用性检测 | ✅ 已完成 | `PKPaymentAuthorizationController.canMakePayments` |
| 支付网络支持 | ✅ 已完成 | Visa / MasterCard / Amex / UnionPay / JCB / Discover |
| 支付请求构建 | ✅ 已完成 | `PKPaymentRequest` + merchantIdentifier |
| 授权回调处理 | ✅ 已完成 | `PKPaymentAuthorizationControllerDelegate` |
| 服务端 Token 处理 | ✅ 已完成 | `paymentToken.paymentData` → base64 → Server |

### Stripe (REST API 直调)

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| Checkout Session 创建 | ✅ 已完成 | `URLSession` POST → `/api/payments/stripe/create-session` |
| 浏览器跳转支付 | ✅ 已完成 | `UIApplication.open` / `NSWorkspace.open` → Stripe Checkout |
| 支付验证 | ✅ 已完成 | Server-side verify → `/api/payments/stripe/verify` |
| 回调处理 | ✅ 已完成 | `scrollcap://payment/success` Deep Link |

### 微信支付 / 支付宝

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| 微信 App 检测 | ✅ 已完成 | `canOpenURL("weixin://")` |
| 支付宝 App 检测 | ✅ 已完成 | `canOpenURL("alipay://")` |
| 服务端预下单 | ✅ 已完成 | `URLSession` POST → `/api/payments/{wechat,alipay}/create-order` |
| URL Scheme 唤起 | ✅ 已完成 | `UIApplication.open(paymentScheme)` |
| Web 支付降级 | ✅ 已完成 | `webPaymentURL` fallback (macOS / App 未安装时) |
| 订单验证 | ✅ 已完成 | Server-side verify → `/api/payments/verify` |
| 支付回调 | ✅ 已完成 | `scrollcap://payment/{provider}/callback` Deep Link |

### PayPal

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| 服务端下单 | ✅ 已完成 | `URLSession` POST → `/api/payments/paypal/create-order` |
| 浏览器 Approval 跳转 | ✅ 已完成 | `approvalURL` → 浏览器 PayPal 授权 |
| 订单验证 | ✅ 已完成 | Server-side verify |

### 付费墙 UI

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| 支付方式选择器 | ✅ 已完成 | 6 种方式 Grid 切换 (App Store / Apple Pay / Stripe / 微信 / 支付宝 / PayPal) |
| 动态可用性 | ✅ 已完成 | 仅显示当前设备可用的支付方式 |
| 订阅状态展示 | ✅ 已完成 | 到期时间 / 自动续费 / 管理入口 |
| 统一配置 | ✅ 已完成 | `PaymentConfig` 服务端 URL 管理 + Info.plist 可配 |

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
| App Icon | ✅ 已完成 | 蓝紫渐变抽象几何风格，全平台适配 (16px-1024px) |
| MeshGradient 动画背景 | ✅ 已完成 | `AnimatedMeshBackground` (iOS 18+/macOS 15+) + LinearGradient 降级 |
| 品牌色渐变 | ✅ 已完成 | `SCTheme.Gradients.brand` 蓝紫渐变 |
| 三级阴影系统 | ✅ 已完成 | `SCTheme.Shadows.card/elevated/floating` |
| 脉冲动画按钮 | ✅ 已完成 | `CaptureButton` idle 呼吸光环 + 捕获态红色波纹 |
| Glass Card 增强 | ✅ 已完成 | 双层材质 + 渐变描边 + 深浅适配 |
| 品牌化空态 | ✅ 已完成 | `symbolEffect(.bounce)` + 渐变色图标 |
| Floating Action Bar | ✅ 已完成 | `FloatingActionBar` 胶囊形底部控制栏 |
| Hover 交互反馈 | ✅ 已完成 | `ScreenshotCard` scale + shadow 变化 |
| Scale Button Style | ✅ 已完成 | 全局按钮按压缩放效果 |
| Liquid Glass (iOS 26+) | ✅ 已完成 | 编译时降级，Xcode 26 后自动启用 |
| Material 背景 | ✅ 已完成 | `.ultraThinMaterial` / `.thinMaterial` |

---

## 国际化 (i18n)

| 语言 | 状态 | 覆盖范围 |
|------|------|----------|
| English (en) | ✅ 已完成 | 全部 UI 文案（150+ 条） |
| 简体中文 (zh-Hans) | ✅ 已完成 | 全部 UI 文案（150+ 条） |

---

## 深色模式

| 特性 | 状态 | 说明 |
|------|------|------|
| AccentColor 双模式 | ✅ 已完成 | Light: (0, 0.47, 0.98) / Dark: (0.26, 0.58, 1.0) |
| CardBackground 双模式 | ✅ 已完成 | Light: 黑色 6% / Dark: 白色 12% |
| MeshGradient 适配 | ✅ 已完成 | Dark 模式透明度 0.5 / Light 模式 0.3 |
| 卡片背景适配 | ✅ 已完成 | Dark: white.opacity(0.05) / Light: white |
| 阴影适配 | ✅ 已完成 | Dark: 更深阴影 / Light: 柔和阴影 |
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

## 用户模式

### 未成年模式 (Minor Mode)

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| 支付内容隐藏 | ✅ 已完成 | `appState.shouldHidePayment` 条件渲染 Pro/支付相关入口 |
| 使用时长追踪 | ✅ 已完成 | `sessionStartTime` + 定时 `checkUsageTime()` 检查 |
| 时长超限提醒 | ✅ 已完成 | `UsageTimerBanner` 弹出横幅 + 可自定义时限 (默认 40 分钟) |
| 外部链接隐藏 | ✅ 已完成 | 设置中源码链接在未成年模式下不可见 |
| 界面简化 | ✅ 已完成 | 截图详情隐藏编辑器入口 |
| 会话重置 | ✅ 已完成 | 手动重置使用时长计时器 |

### 适老化模式 (Elder Mode)

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| 大字体 | ✅ 已完成 | `UserModeAdaptiveModifier` 全局设置 `.dynamicTypeSize(.xxxLarge)` |
| 大按钮 | ✅ 已完成 | `ElderCaptureButton` 80pt 圆形按钮 + 文字标签 |
| 专用按钮样式 | ✅ 已完成 | `ElderButtonStyle` 自定义 ButtonStyle |
| 动画简化 | ✅ 已完成 | 适老化模式下禁用 transition 和 pulse 动画 |
| 截图详情适配 | ✅ 已完成 | 隐藏工具栏按钮，改为大尺寸 `elderActionButtons` |
| 设置文字适配 | ✅ 已完成 | `adaptiveCaption` 字体放大 |

### 模式管理

| 功能 | 状态 | 技术实现 |
|------|------|----------|
| 三种模式切换 | ✅ 已完成 | `UserMode` 枚举: `.standard` / `.minor` / `.elder` |
| Environment 传递 | ✅ 已完成 | `@Environment(\.userMode)` 自定义环境键 |
| 全局模式修饰器 | ✅ 已完成 | `.applyUserMode()` ViewModifier 应用于 App 根视图 |
| 设置 UI 集成 | ✅ 已完成 | `Picker` 模式选择器 + 图标 + 描述 |

---

## 代码质量

| 工具 | 状态 | 说明 |
|------|------|------|
| SwiftLint | ✅ 已完成 | `.swiftlint.yml` 配置，包含 opt-in 规则，CI 集成 |
| SwiftFormat | ✅ 已完成 | `.swiftformat` 配置，Swift 6.0，120 字符宽度限制 |
| CI Lint Job | ✅ 已完成 | GitHub Actions `lint` job：SwiftLint strict + SwiftFormat --lint |
| Git pre-commit Hook | ✅ 已完成 | 提交前自动检查暂存的 `.swift` 文件，不通过则阻断提交 |
| Git commit-msg Hook | ✅ 已完成 | Conventional Commits 格式校验 (feat/fix/docs/refactor/...) |
| Hook 自动安装 | ✅ 已完成 | `scripts/install-hooks.sh` + `setup.sh` 集成，clone 后一键生效 |

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
│  Analytics / Store / iCloudSync         │
│  UserMode (Minor / Elder)               │
│  ScrollCapWidget (WidgetKit)            │
├─────────────────────────────────────────┤
│          Platform Layer                 │
│  macOS: ScreenCaptureService            │
│  iOS:   ReplayKitCaptureService         │
│         AutoScrollService               │
│         BroadcastExtension              │
├─────────────────────────────────────────┤
│          Core Packages (SPM)            │
│  SharedModels │ DesignSystem            │
│  StitchingEngine │ CaptureKit           │
│  ImageEditor (+ OCRService)             │
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
| 文字识别 | Vision Framework (`VNRecognizeTextRequest`) |
| 图像导出 | ImageIO |
| 内购系统 | StoreKit 2 |
| 云同步 | iCloud Documents + NSMetadataQuery |
| Widget | WidgetKit + AppIntents |
| 日志系统 | OSLog |
| 项目生成 | XcodeGen |
| CI/CD | GitHub Actions |
| 代码检查 | SwiftLint + SwiftFormat |
| 第三方依赖 | **零** |

---

## 未来规划

| 功能 | 优先级 | 说明 |
|------|--------|------|
| 原生 Liquid Glass | 高 | 升级到 Xcode 26 后自动启用 |
| 更多语言支持 | 中 | 日语、韩语、法语等 |
| Live Activity | 中 | 实时活动显示捕获进度 |
| 视频录制模式 | 低 | 滚动过程录制为视频 |
| TestFlight 分发 | 低 | 需要 Apple Developer 账号 |
| 第三方支付 SDK 集成 | 中 | WeChat Pay / Alipay 服务端对接，Stripe SDK 嵌入 |
