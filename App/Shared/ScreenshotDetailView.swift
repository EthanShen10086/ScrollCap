import SwiftUI
import DesignSystem
import SharedModels

struct ScreenshotDetailView: View {
    let screenshot: Screenshot
    @Environment(AppState.self) private var appState
    @State private var showEditor = false
    @State private var showExport = false
    @State private var viewModel = CaptureViewModel()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: SCTheme.Spacing.md) {
                imagePreview(in: geometry)
                metadataBar
            }
            .padding(SCTheme.Spacing.md)
        }
        .navigationTitle("detail.title")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItemGroup {
                Button {
                    showEditor = true
                } label: {
                    Label("detail.edit", systemImage: "pencil")
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
    }

    private func imagePreview(in geometry: GeometryProxy) -> some View {
        ScrollView([.horizontal, .vertical]) {
            Image(decorative: screenshot.image, scale: 1.0)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: geometry.size.width - SCTheme.Spacing.md * 2)
                .clipShape(RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
    }

    private var metadataBar: some View {
        HStack(spacing: SCTheme.Spacing.lg) {
            metadataItem(icon: "ruler", label: String(localized: "detail.size"), value: "\(screenshot.image.width)×\(screenshot.image.height)")
            metadataItem(icon: "square.stack.3d.up", label: String(localized: "detail.frames"), value: "\(screenshot.metadata.frameCount)")
            metadataItem(icon: "clock", label: String(localized: "detail.duration"), value: String(format: "%.1fs", screenshot.metadata.durationSeconds))
            metadataItem(icon: "gearshape", label: String(localized: "detail.method"), value: screenshot.metadata.captureMethod.rawValue)
        }
        .padding(SCTheme.Spacing.sm)
        .adaptiveGlass(cornerRadius: SCTheme.CornerRadius.md)
    }

    private func metadataItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(SCTheme.Typography.monoCaption)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
    }
}
