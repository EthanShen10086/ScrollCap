import DesignSystem
import SharedModels
import SwiftUI

struct ExportSheet: View {
    let screenshot: Screenshot
    @Environment(\.dismiss) private var dismiss
    @Environment(\.userMode) private var userMode
    @State private var selectedFormat: ExportFormat = .png
    @State private var quality: Double = 0.9
    @State private var isSaving = false
    @State private var showPaywall = false

    private var availableFormats: [ExportFormat] {
        if EntitlementManager.shared.isPro {
            return ExportFormat.allCases
        }
        return [.png, .jpeg]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("export.format") {
                    Picker("export.format", selection: self.$selectedFormat) {
                        ForEach(self.availableFormats) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)

                    if !EntitlementManager.shared.isPro, self.userMode != .minor {
                        Button {
                            self.showPaywall = true
                            AnalyticsManager.shared.track(.proUpgradeTapped)
                        } label: {
                            Label("pro.feature.formats", systemImage: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if self.selectedFormat.supportedCompressionQuality {
                        VStack(alignment: .leading) {
                            Text("export.quality \(Int(self.quality * 100))")
                            Slider(value: self.$quality, in: 0.1 ... 1.0, step: 0.05)
                        }
                    }
                }

                Section("export.info") {
                    LabeledContent(
                        "export.dimensions",
                        value: "\(self.screenshot.image.width)×\(self.screenshot.image.height)"
                    )
                    LabeledContent("export.frames", value: "\(self.screenshot.metadata.frameCount)")
                }

                Section {
                    Button {
                        Task { await self.saveImage() }
                    } label: {
                        HStack {
                            Spacer()
                            if self.isSaving {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("export.save", systemImage: "square.and.arrow.down")
                            }
                            Spacer()
                        }
                    }
                    .disabled(self.isSaving)

                    #if os(iOS)
                    ShareLink(
                        item: Image(decorative: self.screenshot.image, scale: 1.0),
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
                        Button("capture.cancel") { self.dismiss() }
                    }
                }
        }
        #if os(macOS)
        .frame(minWidth: 350, minHeight: 300)
        #endif
        .sheet(isPresented: self.$showPaywall) {
            PaywallView()
        }
    }

    private func saveImage() async {
        self.isSaving = true
        defer { isSaving = false }

        let options = ExportOptions(format: selectedFormat, compressionQuality: quality)
        let service = ExportService()

        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [self.selectedFormat.utType]
        panel.nameFieldStringValue = "ScrollCap_\(Int(Date().timeIntervalSince1970)).\(self.selectedFormat.fileExtension)"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            try await service.export(image: self.screenshot.image, options: options, to: url)
            AnalyticsManager.shared.track(.exportSaved(format: self.selectedFormat.fileExtension))
            self.dismiss()
        } catch {
            ErrorPresenter.shared.present(.export(.fileWriteFailed))
        }
        #elseif os(iOS)
        do {
            let data = try await service.exportToData(image: self.screenshot.image, options: options)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                "ScrollCap_\(Int(Date().timeIntervalSince1970)).\(self.selectedFormat.fileExtension)"
            )
            try data.write(to: tempURL)
            AnalyticsManager.shared.track(.exportSaved(format: self.selectedFormat.fileExtension))
            self.dismiss()
        } catch {
            ErrorPresenter.shared.present(.export(.fileWriteFailed))
        }
        #endif
    }
}
