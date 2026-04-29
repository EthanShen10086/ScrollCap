import SwiftUI
import DesignSystem
import SharedModels

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        Form {
            Section("Export") {
                Picker("Format", selection: $state.exportFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }

                if appState.exportFormat.supportedCompressionQuality {
                    VStack(alignment: .leading) {
                        Text("Quality: \(Int(appState.exportQuality * 100))%")
                        Slider(value: $state.exportQuality, in: 0.1...1.0, step: 0.05)
                    }
                }
            }

            Section("Capture") {
                #if os(macOS)
                macOSCaptureSettings
                #else
                iOSCaptureSettings
                #endif
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "1")

                Link(destination: URL(string: "https://github.com/EthanShen10086/ScrollCap")!) {
                    Label("Source Code", systemImage: "curlybraces")
                }
            }
        }
        .navigationTitle("Settings")
        #if os(macOS)
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 300)
        #endif
    }

    #if os(macOS)
    private var macOSCaptureSettings: some View {
        Group {
            LabeledContent("Capture Method", value: "ScreenCaptureKit")

            Toggle("Show cursor in capture", isOn: .constant(false))

            LabeledContent("Frame Rate", value: "10 fps")
        }
    }
    #endif

    #if os(iOS)
    private var iOSCaptureSettings: some View {
        Group {
            LabeledContent("Capture Method", value: "ReplayKit")

            Text("Tap the capture button, then switch to the target app and scroll. ScrollCap will record and stitch the frames automatically.")
                .font(SCTheme.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }
    #endif
}
