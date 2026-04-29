import XCTest
@testable import DesignSystem

final class DesignSystemTests: XCTestCase {
    func testThemeSpacingValues() {
        XCTAssertLessThan(SCTheme.Spacing.xs, SCTheme.Spacing.sm)
        XCTAssertLessThan(SCTheme.Spacing.sm, SCTheme.Spacing.md)
        XCTAssertLessThan(SCTheme.Spacing.md, SCTheme.Spacing.lg)
    }

    func testThemeCornerRadiusValues() {
        XCTAssertLessThan(SCTheme.CornerRadius.sm, SCTheme.CornerRadius.md)
        XCTAssertLessThan(SCTheme.CornerRadius.md, SCTheme.CornerRadius.lg)
    }
}
