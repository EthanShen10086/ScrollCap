import DesignSystem
import SharedModels
import SwiftUI

struct ExportSheet: View {
    let screenshot: Screenshot
    let viewModel: CaptureViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .png
    @State private var quality: Double = 0.9
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("export.format") {
                    Picker("export.format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedFormat.supportedCompressionQuality {
                        VStack(alignment: .leading) {
                            Text("export.quality \(Int(quality * 100))")
                            Slider(value: $quality, in: 0.1 ... 1.0, step: 0.05)
                        }
                    }
                }

                Section("export.info") {
                    LabeledContent("export.dimensions", value: "\(screenshot.image.width)×\(screenshot.image.height)")
                    LabeledContent("export.frames", value: "\(screenshot.metadata.frameCount)")
                }

                Section {
                    Button {
                        Task { await saveImage() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("export.save", systemImage: "square.and.arrow.down")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSaving)

                    #if os(iOS)
                    ShareLink(
                        item: Image(decorative: screenshot.image, scale: 1.0),
                        preview: SharePreview(Text("export.sharePreview"))
                    ) {
                        HStack {
                            Spacer()
                            Label("export.share", systemImage: "square.and.arrow.up")
                            Spacer()
                        }
                    }
                    #endif
                }
            }
            .navigationTitle("export.title")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("capture.cancel") { dismiss() }
                    }
                }
        }
        #if os(macOS)
        .frame(minWidth: 350, minHeight: 300)
        #endif
    }

    private func saveImage() async {
        isSaving = true
        defer { isSaving = false }

        let options = ExportOptions(format: selectedFormat, compressionQuality: quality)

        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [selectedFormat.utType]
        panel.nameFieldStringValue = "ScrollCap_\(Int(Date().timeIntervalSince1970)).\(selectedFormat.fileExtension)"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            try await viewModel.exportScreenshot(options: options, to: url)
            AnalyticsManager.shared.track(.exportSaved(format: selectedFormat.fileExtension))
            dismiss()
        } catch {
            ErrorPresenter.shared.present(.export(.fileWriteFailed))
        }
        #elseif os(iOS)
        do {
            if let data = try await viewModel.exportToData(options: options) {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                    "ScrollCap_\(Int(Date().timeIntervalSince1970)).\(selectedFormat.fileExtension)"
                )
                try data.write(to: tempURL)
                AnalyticsManager.shared.track(.exportSaved(format: selectedFormat.fileExtension))
                dismiss()
            }
        } catch {
            ErrorPresenter.shared.present(.export(.fileWriteFailed))
        }
        #endif
    }
}
