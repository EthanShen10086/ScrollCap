import DesignSystem
import ImageEditor
import SharedModels
import SwiftUI

struct ScreenshotDetailView: View {
    let screenshot: Screenshot
    @Environment(AppState.self) private var appState
    @Environment(\.userMode) private var userMode
    @State private var showEditor = false
    @State private var showExport = false
    @State private var showOCR = false
    @State private var showPaywall = false
    @State private var viewModel = CaptureViewModel()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: SCTheme.Spacing.md) {
                self.imagePreview(in: geometry)
                self.metadataBar

                if self.userMode == .elder {
                    self.elderActionButtons
                }

                Spacer()

                #if os(iOS)
                if self.userMode != .elder {
                    self.detailFloatingBar
                }
                #endif
            }
            .padding(SCTheme.Spacing.md)
        }
        .background { BrandBackground() }
        .onAppear { AnalyticsManager.shared.track(.screenshotOpened) }
        .navigationTitle("detail.title")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar {
                #if os(macOS)
                if self.userMode != .elder {
                    ToolbarItemGroup {
                        Button {
                            self.proAction(.ocr) { self.showOCR = true }
                        } label: {
                            Label("ocr.title", systemImage: "text.viewfinder")
                        }

                        if self.userMode != .minor {
                            Button {
                                self.proAction(.imageEditor) { self.showEditor = true }
                            } label: {
                                Label("detail.edit", systemImage: "pencil")
                            }
                        }

                        Button {
                            self.showExport = true
                        } label: {
                            Label("detail.export", systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive) {
                            self.appState.removeScreenshot(self.screenshot)
                        } label: {
                            Label("detail.delete", systemImage: "trash")
                        }
                    }
                }
                #endif
            }
            .sheet(isPresented: self.$showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: self.$showEditor) {
                NavigationStack {
                    ImageEditorView(screenshot: self.screenshot)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("detail.done") { self.showEditor = false }
                            }
                        }
                }
                #if os(macOS)
                .frame(minWidth: 600, minHeight: 400)
                #endif
            }
            .sheet(isPresented: self.$showExport) {
                ExportSheet(screenshot: self.screenshot, viewModel: self.viewModel)
            }
            .sheet(isPresented: self.$showOCR) {
                OCRResultView(image: self.screenshot.image)
            }
    }

    private func imagePreview(in geometry: GeometryProxy) -> some View {
        ScrollView([.horizontal, .vertical]) {
            Image(decorative: self.screenshot.image, scale: 1.0)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: geometry.size.width - SCTheme.Spacing.md * 2)
                .clipShape(RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md))
                .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
        }
    }

    private var metadataBar: some View {
        HStack(spacing: SCTheme.Spacing.lg) {
            self.metadataItem(
                icon: "ruler",
                label: String(localized: "detail.size"),
                value: "\(self.screenshot.image.width)×\(self.screenshot.image.height)"
            )
            self.metadataItem(
                icon: "square.stack.3d.up",
                label: String(localized: "detail.frames"),
                value: "\(self.screenshot.metadata.frameCount)"
            )
            self.metadataItem(
                icon: "clock",
                label: String(localized: "detail.duration"),
                value: String(
                    localized: "detail.duration.value \(String(format: "%.1f", self.screenshot.metadata.durationSeconds))"
                )
            )
            self.metadataItem(
                icon: "gearshape",
                label: String(localized: "detail.method"),
                value: self.screenshot.metadata.captureMethod.localizedName
            )
        }
        .padding(SCTheme.Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg))
    }

    private func metadataItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(self.userMode == .elder ? .body : .caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(value)
                .font(self.userMode == .elder ? .body.monospaced() : SCTheme.Typography.monoCaption)
            Text(label)
                .font(self.userMode == .elder ? .caption : .system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var elderActionButtons: some View {
        VStack(spacing: SCTheme.Spacing.md) {
            HStack(spacing: SCTheme.Spacing.md) {
                self.elderActionButton(
                    title: String(localized: "detail.export"),
                    icon: "square.and.arrow.up",
                    color: .blue
                ) {
                    self.showExport = true
                }
                self.elderActionButton(title: String(localized: "detail.delete"), icon: "trash", color: .red) {
                    self.appState.removeScreenshot(self.screenshot)
                }
            }

            HStack(spacing: SCTheme.Spacing.md) {
                self.elderActionButton(title: String(localized: "ocr.title"), icon: "text.viewfinder", color: .purple) {
                    self.proAction(.ocr) { self.showOCR = true }
                }
                self.elderActionButton(title: String(localized: "detail.edit"), icon: "pencil", color: .orange) {
                    self.proAction(.imageEditor) { self.showEditor = true }
                }
            }
        }
        .padding(.top, SCTheme.Spacing.sm)
    }

    #if os(iOS)
    private var detailFloatingBar: some View {
        FloatingActionBar {
            HStack(spacing: SCTheme.Spacing.lg) {
                Button {
                    self.proAction(.ocr) { self.showOCR = true }
                } label: {
                    Label("ocr.title", systemImage: "text.viewfinder")
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel(Text("ocr.title"))

                if self.userMode != .minor {
                    Button {
                        self.proAction(.imageEditor) { self.showEditor = true }
                    } label: {
                        Label("detail.edit", systemImage: "pencil")
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel(Text("detail.edit"))
                }

                Button {
                    self.showExport = true
                } label: {
                    Label("detail.export", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel(Text("detail.export"))

                Button(role: .destructive) {
                    self.appState.removeScreenshot(self.screenshot)
                    AnalyticsManager.shared.track(.screenshotDeleted)
                } label: {
                    Label("detail.delete", systemImage: "trash")
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel(Text("detail.delete"))
            }
            .font(.system(size: 20))
        }
    }
    #endif

    private func elderActionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.title3.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg))
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }

    private func proAction(_ feature: ProFeature, perform action: () -> Void) {
        if EntitlementManager.shared.isPro {
            action()
        } else if self.userMode == .minor {
            return
        } else {
            AnalyticsManager.shared.track(.proUpgradeTapped)
            self.showPaywall = true
        }
    }
}
