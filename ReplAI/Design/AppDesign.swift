import SwiftUI

/// Single source of truth for every visual token in ReplAI.
/// Changing a value here propagates to all views automatically.
enum AppDesign {

    /// App Group identifier shared between the main app and Share Extension.
    static let appGroupID = "group.com.huseyinataseven.replai"

    /// Filename used to pass screenshot data from Share Extension → main app.
    static let pendingImageFilename = "pendingImage.jpg"

    /// UserDefaults key caching the subscription state for extensions that cannot
    /// run StoreKit (Action Extension). Written by the main app on every entitlement refresh.
    static let isSubscribedKey = "cachedIsSubscribed"

    /// UserDefaults key for the one-time nonce written by the Share Extension.
    /// The main app verifies its presence before processing a replai://analyze URL,
    /// preventing third-party apps from triggering the analysis flow.
    static let pendingNonceKey = "pendingAnalysisNonce"

    enum Spacing {
        static let xs:  Double = 4
        static let sm:  Double = 8
        static let md:  Double = 16
        static let lg:  Double = 24
        static let xl:  Double = 32
        static let xxl: Double = 48
    }

    enum Radius {
        static let sm: Double = 10
        static let md: Double = 18
        static let lg: Double = 26
    }

    enum Color {
        /// True black-navy background
        static let background     = SwiftUI.Color(red: 0.066, green: 0.066, blue: 0.10)
        /// Slightly lighter surface for cards
        static let surface        = SwiftUI.Color(red: 0.11,  green: 0.11,  blue: 0.17)
        /// Subtle border / divider
        static let border         = SwiftUI.Color.white.opacity(0.08)
        static let textPrimary    = SwiftUI.Color.white
        static let textSecondary  = SwiftUI.Color.white.opacity(0.55)
        /// Purple accent used for CTAs and highlights
        static let accent         = SwiftUI.Color(red: 0.52, green: 0.32, blue: 0.95)
        static let accentGradient = LinearGradient(
            colors: [
                SwiftUI.Color(red: 0.52, green: 0.32, blue: 0.95),
                SwiftUI.Color(red: 0.27, green: 0.55, blue: 0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Font {
        static let largeTitle = SwiftUI.Font.system(.largeTitle,  design: .rounded, weight: .bold)
        static let title      = SwiftUI.Font.system(.title,       design: .rounded, weight: .bold)
        static let title2     = SwiftUI.Font.system(.title2,      design: .rounded, weight: .semibold)
        static let headline   = SwiftUI.Font.system(.headline,    design: .rounded)
        static let body       = SwiftUI.Font.system(.body,        design: .rounded)
        static let subhead    = SwiftUI.Font.system(.subheadline, design: .rounded)
    }

    enum Anim {
        static let standard = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.80)
        static let slow     = SwiftUI.Animation.easeInOut(duration: 0.45)
        static let snappy   = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.75)
    }
}
