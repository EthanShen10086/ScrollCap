import Testing
@testable import DesignSystem

@Test func themeSpacingValues() {
    #expect(SCTheme.Spacing.xs < SCTheme.Spacing.sm)
    #expect(SCTheme.Spacing.sm < SCTheme.Spacing.md)
    #expect(SCTheme.Spacing.md < SCTheme.Spacing.lg)
}

@Test func themeCornerRadiusValues() {
    #expect(SCTheme.CornerRadius.sm < SCTheme.CornerRadius.md)
    #expect(SCTheme.CornerRadius.md < SCTheme.CornerRadius.lg)
}
