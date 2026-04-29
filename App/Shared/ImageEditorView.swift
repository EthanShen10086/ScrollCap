import DesignSystem
import ImageEditor
import SharedModels
import SwiftUI

struct ImageEditorView: View {
    let screenshot: Screenshot
    @State private var editedImage: CGImage
    @State private var selectedTool: EditorTool = .none
    @Environment(\.userMode) private var userMode
    @State private var cropRect: CGRect = .zero
    @State private var isCropping = false
    @State private var annotations: [Annotation] = []
    @State private var selectedColor: AnnotationColor = .red
    @State private var lineWidth: CGFloat = 3

    init(screenshot: Screenshot) {
        self.screenshot = screenshot
        _editedImage = State(initialValue: screenshot.image)
    }

    var body: some View {
        VStack(spacing: 0) {
            self.toolbar

            Divider()

            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    Image(decorative: self.editedImage, scale: 1.0)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geometry.size.width)
                        .overlay {
                            if self.isCropping {
                                self.cropOverlay
                            }
                        }
                }
            }
        }
        .navigationTitle("editor.title")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SCTheme.Spacing.sm) {
                self.toolButton(.none, "hand.raised", String(localized: "editor.select"))
                self.toolButton(.crop, "crop", String(localized: "editor.crop"))
                self.toolButton(.rectangle, "rectangle", String(localized: "editor.rectangle"))
                self.toolButton(.arrow, "arrow.up.right", String(localized: "editor.arrow"))
                self.toolButton(.highlight, "highlighter", String(localized: "editor.highlight"))

                Divider()
                    .frame(height: 24)

                self.colorPicker
            }
            .padding(.horizontal, SCTheme.Spacing.md)
            .padding(.vertical, SCTheme.Spacing.sm)
        }
        .adaptiveGlass(cornerRadius: 0)
    }

    private func toolButton(_ tool: EditorTool, _ icon: String, _ label: String) -> some View {
        Button {
            self.selectedTool = tool
            if tool == .crop {
                self.isCropping = true
            } else {
                self.isCropping = false
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundStyle(self.selectedTool == tool ? Color.accentColor : .secondary)
            .frame(width: self.userMode == .elder ? 64 : 48, height: self.userMode == .elder ? 56 : 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(self.selectedTool == tool ? [.isButton, .isSelected] : .isButton)
    }

    private var colorPicker: some View {
        HStack(spacing: SCTheme.Spacing.xs) {
            ForEach(self.annotationColors, id: \.name) { item in
                Circle()
                    .fill(Color(cgColor: item.color.cgColor))
                    .frame(width: self.userMode == .elder ? 32 : 20, height: self.userMode == .elder ? 32 : 20)
                    .overlay {
                        if self.selectedColor.cgColor == item.color.cgColor {
                            Circle()
                                .stroke(.white, lineWidth: 2)
                                .frame(
                                    width: self.userMode == .elder ? 36 : 24,
                                    height: self.userMode == .elder ? 36 : 24
                                )
                        }
                    }
                    .padding(self.userMode == .elder ? 8 : 4)
                    .contentShape(Circle())
                    .onTapGesture {
                        self.selectedColor = item.color
                    }
                    .accessibilityLabel(item.name)
                    .accessibilityAddTraits(self.selectedColor.cgColor == item.color
                        .cgColor ? [.isButton, .isSelected] : .isButton)
            }
        }
    }

    private var annotationColors: [(name: String, color: AnnotationColor)] {
        [
            (String(localized: "a11y.color.red"), .red),
            (String(localized: "a11y.color.blue"), .blue),
            (String(localized: "a11y.color.green"), .green),
            (String(localized: "a11y.color.yellow"), .yellow),
            (String(localized: "a11y.color.white"), .white),
            (String(localized: "a11y.color.black"), .black),
        ]
    }

    // MARK: - Crop Overlay

    private var cropOverlay: some View {
        ZStack {
            SCTheme.Colors.overlayBackground

            VStack(spacing: SCTheme.Spacing.md) {
                Text("editor.cropHint")
                    .font(SCTheme.Typography.caption)
                    .foregroundStyle(.white)

                HStack {
                    Button("capture.cancel") {
                        self.isCropping = false
                        self.selectedTool = .none
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)

                    Button("editor.applyCrop") {
                        self.applyCrop()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    // MARK: - Actions

    private func applyCrop() {
        guard self.cropRect != .zero else {
            self.isCropping = false
            return
        }

        let tool = CropTool()
        if let cropped = tool.crop(image: editedImage, to: cropRect) {
            self.editedImage = cropped
        }

        self.isCropping = false
        self.selectedTool = .none
    }
}

enum EditorTool {
    case none
    case crop
    case rectangle
    case arrow
    case highlight
}
