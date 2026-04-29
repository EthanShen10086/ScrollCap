import DesignSystem
import ImageEditor
import SharedModels
import SwiftUI

struct ImageEditorView: View {
    let screenshot: Screenshot
    @State private var editedImage: CGImage
    @State private var selectedTool: EditorTool = .none
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
            toolbar

            Divider()

            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    Image(decorative: editedImage, scale: 1.0)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geometry.size.width)
                        .overlay {
                            if isCropping {
                                cropOverlay
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
                toolButton(.none, "hand.raised", String(localized: "editor.select"))
                toolButton(.crop, "crop", String(localized: "editor.crop"))
                toolButton(.rectangle, "rectangle", String(localized: "editor.rectangle"))
                toolButton(.arrow, "arrow.up.right", String(localized: "editor.arrow"))
                toolButton(.highlight, "highlighter", String(localized: "editor.highlight"))

                Divider()
                    .frame(height: 24)

                colorPicker
            }
            .padding(.horizontal, SCTheme.Spacing.md)
            .padding(.vertical, SCTheme.Spacing.sm)
        }
        .adaptiveGlass(cornerRadius: 0)
    }

    private func toolButton(_ tool: EditorTool, _ icon: String, _ label: String) -> some View {
        Button {
            selectedTool = tool
            if tool == .crop {
                isCropping = true
            } else {
                isCropping = false
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundStyle(selectedTool == tool ? Color.accentColor : .secondary)
            .frame(width: 48, height: 42)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selectedTool == tool ? [.isButton, .isSelected] : .isButton)
    }

    private var colorPicker: some View {
        HStack(spacing: SCTheme.Spacing.xs) {
            ForEach(annotationColors, id: \.name) { item in
                Circle()
                    .fill(Color(cgColor: item.color.cgColor))
                    .frame(width: 20, height: 20)
                    .overlay {
                        if selectedColor.cgColor == item.color.cgColor {
                            Circle()
                                .stroke(.white, lineWidth: 2)
                                .frame(width: 24, height: 24)
                        }
                    }
                    .onTapGesture {
                        selectedColor = item.color
                    }
                    .accessibilityLabel(item.name)
                    .accessibilityAddTraits(selectedColor.cgColor == item.color
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
                        isCropping = false
                        selectedTool = .none
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)

                    Button("editor.applyCrop") {
                        applyCrop()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    // MARK: - Actions

    private func applyCrop() {
        guard cropRect != .zero else {
            isCropping = false
            return
        }

        let tool = CropTool()
        if let cropped = tool.crop(image: editedImage, to: cropRect) {
            editedImage = cropped
        }

        isCropping = false
        selectedTool = .none
    }
}

enum EditorTool {
    case none
    case crop
    case rectangle
    case arrow
    case highlight
}
