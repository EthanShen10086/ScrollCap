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
                imagePreview(in: geometry)
                metadataBar

                if userMode == .elder {
                    elderActionButtons
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
                if userMode != .elder {
                    ToolbarItemGroup {
                        Button {
                            showOCR = true
                        } label: {
                            Label("OCR", systemImage: "text.viewfinder")
                        }

                        if userMode != .minor {
                            Button {
                                showEditor = true
                            } label: {
                                Label("detail.edit", systemImage: "pencil")
                            }
                        }

                        Button {
                            showExport = true
                        } label: {
                            Label("detail.export", systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive) {
                            appState.removeScreenshot(screenshot)
                        } label: {
                            Label("detail.delete", systemImage: "trash")
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                NavigationStack {
                    ImageEditorView(screenshot: screenshot)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("detail.done") { showEditor = false }
                            }
                        }
                }
                #if os(macOS)
                .frame(minWidth: 600, minHeight: 400)
                #endif
            }
            .sheet(isPresented: $showExport) {
                ExportSheet(screenshot: screenshot, viewModel: viewModel)
            }
            .sheet(isPresented: $showOCR) {
                OCRResultView(image: screenshot.image)
            }
    }

    private func imagePreview(in geometry: GeometryProxy) -> some View {
        ScrollView([.horizontal, .vertical]) {
            Image(decorative: screenshot.image, scale: 1.0)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: geometry.size.width - SCTheme.Spacing.md * 2)
                .clipShape(RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md))
                .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
        }
    }

    private var metadataBar: some View {
        HStack(spacing: SCTheme.Spacing.lg) {
            metadataItem(
                icon: "ruler",
                label: String(localized: "detail.size"),
                value: "\(screenshot.image.width)×\(screenshot.image.height)"
            )
            metadataItem(
                icon: "square.stack.3d.up",
                label: String(localized: "detail.frames"),
                value: "\(screenshot.metadata.frameCount)"
            )
            metadataItem(
                icon: "clock",
                label: String(localized: "detail.duration"),
                value: String(format: "%.1fs", screenshot.metadata.durationSeconds)
            )
            metadataItem(
                icon: "gearshape",
                label: String(localized: "detail.method"),
                value: screenshot.metadata.captureMethod.rawValue
            )
        }
        .padding(SCTheme.Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg))
    }

    private func metadataItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(userMode == .elder ? .body : .caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(value)
                .font(userMode == .elder ? .body.monospaced() : SCTheme.Typography.monoCaption)
            Text(label)
                .font(userMode == .elder ? .caption : .system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var elderActionButtons: some View {
        VStack(spacing: SCTheme.Spacing.md) {
            HStack(spacing: SCTheme.Spacing.md) {
                elderActionButton(
                    title: String(localized: "detail.export"),
                    icon: "square.and.arrow.up",
                    color: .blue
                ) {
                    showExport = true
                }
                elderActionButton(title: String(localized: "detail.delete"), icon: "trash", color: .red) {
                    appState.removeScreenshot(screenshot)
                }
            }

            HStack(spacing: SCTheme.Spacing.md) {
                elderActionButton(title: "OCR", icon: "text.viewfinder", color: .purple) {
                    showOCR = true
                }
                elderActionButton(title: String(localized: "detail.edit"), icon: "pencil", color: .orange) {
                    showEditor = true
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
    }
}

// MARK: - OCR Result View

struct OCRResultView: View {
    let image: CGImage
    @Environment(\.dismiss) private var dismiss
    @State private var recognizedText = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    VStack(spacing: SCTheme.Spacing.md) {
                        ProgressView()
                            .controlSize(.large)
                        Text("ocr.processing")
                            .font(SCTheme.Typography.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: SCTheme.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(SCTheme.Typography.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        Text(recognizedText)
                            .font(SCTheme.Typography.body)
                            .textSelection(.enabled)
                            .padding(SCTheme.Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .navigationTitle("ocr.title")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("detail.done") { dismiss() }
                    }

                    if !recognizedText.isEmpty {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                copyToClipboard()
                            } label: {
                                Label("ocr.copy", systemImage: "doc.on.doc")
                            }
                        }
                    }
                }
        }
        .task {
            await performOCR()
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 300)
        #endif
    }

    private func performOCR() async {
        let ocrService = OCRService()
        do {
            let text = try await ocrService.recognizeFullText(in: image)
            recognizedText = text.isEmpty ? String(localized: "ocr.noText") : text
            if !text.isEmpty {
                AnalyticsManager.shared.track(.ocrPerformed(characterCount: text.count))
            }
        } catch {
            errorMessage = error.localizedDescription
            AnalyticsManager.shared.track(.ocrFailed(error: error.localizedDescription))
        }
        isLoading = false
    }

    private func copyToClipboard() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(recognizedText, forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = recognizedText
        #endif
    }
}
