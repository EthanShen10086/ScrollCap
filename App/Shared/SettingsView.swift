import SwiftUI
import DesignSystem
import SharedModels

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        Form {
            Section("settings.export") {
                Picker("export.format", selection: $state.exportFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }

                if appState.exportFormat.supportedCompressionQuality {
                    VStack(alignment: .leading) {
                        Text("export.quality \(Int(appState.exportQuality * 100))")
                        Slider(value: $state.exportQuality, in: 0.1...1.0, step: 0.05)
                    }
                }
            }

            Section("settings.capture") {
                #if os(macOS)
                macOSCaptureSettings
                #else
                iOSCaptureSettings
                #endif
            }

            Section("settings.about") {
                LabeledContent("settings.version", value: "1.0.0")
                LabeledContent("settings.build", value: "1")

                Link(destination: URL(string: "https://github.com/EthanShen10086/ScrollCap")!) {
                    Label("settings.sourceCode", systemImage: "curlybraces")
                }
            }
        }
        .navigationTitle("nav.settings")
        #if os(macOS)
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 300)
        #endif
    }

    #if os(macOS)
    private var macOSCaptureSettings: some View {
        Group {
            LabeledContent("settings.captureMethod", value: String(localized: "method.screenCaptureKit"))

            Toggle("settings.showCursor", isOn: .constant(false))

            LabeledContent("settings.frameRate", value: "10 fps")
        }
    }
    #endif

    #if os(iOS)
    private var iOSCaptureSettings: some View {
        Group {
            LabeledContent("settings.captureMethod", value: String(localized: "method.replayKit"))

            Text("settings.ios.captureDesc")
                .font(SCTheme.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }
    #endif
}
