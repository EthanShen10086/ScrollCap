import DesignSystem
import ImageEditor
import SwiftUI

struct OCRResultView: View {
    let image: CGImage
    @Environment(\.dismiss) private var dismiss
    @State private var recognizedText = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack {
                if self.isLoading {
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
                        Text(self.recognizedText)
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
                        Button("detail.done") { self.dismiss() }
                    }

                    if !self.recognizedText.isEmpty {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                self.copyToClipboard()
                            } label: {
                                Label("ocr.copy", systemImage: "doc.on.doc")
                            }
                        }
                    }
                }
        }
        .task {
            await self.performOCR()
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 300)
        #endif
    }

    private func performOCR() async {
        let ocrService = OCRService()
        do {
            let text = try await ocrService.recognizeFullText(in: self.image)
            self.recognizedText = text.isEmpty ? String(localized: "ocr.noText") : text
            if !text.isEmpty {
                AnalyticsManager.shared.track(.ocrPerformed(characterCount: text.count))
            }
        } catch {
            self.errorMessage = error.localizedDescription
            AnalyticsManager.shared.track(.ocrFailed(error: error.localizedDescription))
        }
        self.isLoading = false
    }

    private func copyToClipboard() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(self.recognizedText, forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = self.recognizedText
        #endif
    }
}
