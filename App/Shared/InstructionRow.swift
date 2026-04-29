import DesignSystem
import SwiftUI

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: SCTheme.Spacing.sm) {
            Text("\(number)")
                .font(.system(.caption, design: .rounded).bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(SCTheme.Gradients.brand, in: Circle())

            Text(text)
                .font(SCTheme.Typography.body)
                .foregroundStyle(.primary)

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
