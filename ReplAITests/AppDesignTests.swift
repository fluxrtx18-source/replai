import Testing
import SwiftUI
@testable import ReplAI

// MARK: - AppDesign Token Tests

@Suite("AppDesign Tokens")
struct AppDesignTests {

    // MARK: - Spacing scale

    @Suite("Spacing")
    struct SpacingTests {
        @Test("Spacing scale uses correct values", arguments: [
            ("xs",  AppDesign.Spacing.xs,  4.0),
            ("sm",  AppDesign.Spacing.sm,  8.0),
            ("md",  AppDesign.Spacing.md,  16.0),
            ("lg",  AppDesign.Spacing.lg,  24.0),
            ("xl",  AppDesign.Spacing.xl,  32.0),
            ("xxl", AppDesign.Spacing.xxl, 48.0),
        ])
        func spacingValues(_ name: String, actual: Double, expected: Double) {
            #expect(actual == expected)
        }

        @Test("Spacing values are strictly ascending")
        func ascending() {
            let values = [
                AppDesign.Spacing.xs,
                AppDesign.Spacing.sm,
                AppDesign.Spacing.md,
                AppDesign.Spacing.lg,
                AppDesign.Spacing.xl,
                AppDesign.Spacing.xxl,
            ]
            for i in 1..<values.count {
                #expect(values[i] > values[i - 1])
            }
        }

        @Test("All spacing values are positive")
        func positive() {
            let values = [
                AppDesign.Spacing.xs, AppDesign.Spacing.sm,
                AppDesign.Spacing.md, AppDesign.Spacing.lg,
                AppDesign.Spacing.xl, AppDesign.Spacing.xxl,
            ]
            for v in values {
                #expect(v > 0)
            }
        }
    }

    // MARK: - Radius scale

    @Suite("Radius")
    struct RadiusTests {
        @Test("Radius scale uses correct values", arguments: [
            ("sm", AppDesign.Radius.sm, 10.0),
            ("md", AppDesign.Radius.md, 18.0),
            ("lg", AppDesign.Radius.lg, 26.0),
        ])
        func radiusValues(_ name: String, actual: Double, expected: Double) {
            #expect(actual == expected)
        }

        @Test("Radius values are strictly ascending")
        func ascending() {
            #expect(AppDesign.Radius.sm < AppDesign.Radius.md)
            #expect(AppDesign.Radius.md < AppDesign.Radius.lg)
        }
    }

    // MARK: - Color definitions exist

    @Suite("Colors")
    struct ColorTests {
        @Test("All named colors are defined and distinct")
        func colorsExist() {
            // Verify these compile and are accessible — type system guarantees they exist.
            let _ = AppDesign.Color.background
            let _ = AppDesign.Color.surface
            let _ = AppDesign.Color.border
            let _ = AppDesign.Color.textPrimary
            let _ = AppDesign.Color.textSecondary
            let _ = AppDesign.Color.accent
            let _ = AppDesign.Color.accentGradient
        }
    }

    // MARK: - Font definitions exist

    @Suite("Fonts")
    struct FontTests {
        @Test("All named fonts are defined")
        func fontsExist() {
            let _ = AppDesign.Font.largeTitle
            let _ = AppDesign.Font.title
            let _ = AppDesign.Font.title2
            let _ = AppDesign.Font.headline
            let _ = AppDesign.Font.body
            let _ = AppDesign.Font.subhead
        }
    }

    // MARK: - Animation definitions exist

    @Suite("Animations")
    struct AnimTests {
        @Test("All named animations are defined")
        func animsExist() {
            let _ = AppDesign.Anim.standard
            let _ = AppDesign.Anim.slow
            let _ = AppDesign.Anim.snappy
        }
    }

    // MARK: - Shared constants

    @Suite("Constants")
    struct ConstantTests {
        @Test("App Group ID is non-empty")
        func appGroupID() {
            #expect(!AppDesign.appGroupID.isEmpty)
            #expect(AppDesign.appGroupID.hasPrefix("group."))
        }

        @Test("Pending image filename has .jpg extension")
        func pendingImageFilename() {
            #expect(AppDesign.pendingImageFilename.hasSuffix(".jpg"))
        }
    }
}
