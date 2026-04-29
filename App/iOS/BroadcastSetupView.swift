#if os(iOS)
import SwiftUI
import ReplayKit

struct BroadcastPickerRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        picker.preferredExtension = Bundle.main.bundleIdentifier.map { $0 + ".BroadcastExtension" }
        picker.showsMicrophoneButton = false

        if let button = picker.subviews.first(where: { $0 is UIButton }) as? UIButton {
            button.imageView?.tintColor = .systemBlue
        }

        return picker
    }

    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {}
}

struct BroadcastSetupView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("ios.startBroadcast")
                .font(.headline)

            BroadcastPickerRepresentable()
                .frame(width: 60, height: 60)

            Text("ios.startBroadcast.desc")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
#endif
