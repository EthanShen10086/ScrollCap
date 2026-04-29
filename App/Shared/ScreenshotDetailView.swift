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
    @State private var viewModel = CaptureViewModel()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: SCTheme.Spacing.md) {
                self.imagePreview(in: geometry)
                self.metadataBar

                if self.userMode == .elder {
                    self.elderActionButtons
                }
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
                if self.userMode != .elder {
                    ToolbarItemGroup {
                        Button {
                            self.showOCR = true
                        } label: {
                            Label("ocr.title", systemImage: "text.viewfinder")
                        }

                        if self.userMode != .minor {
                            Button {
                                self.showEditor = true
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
                    self.showOCR = true
                }
                self.elderActionButton(title: String(localized: "detail.edit"), icon: "pencil", color: .orange) {
                    self.showEditor = true
                }
            }
        }
        .padding(.top, SCTheme.Spacing.sm)
    }

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
}
