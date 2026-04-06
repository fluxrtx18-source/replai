import SwiftUI
#if DEBUG
import StoreKitTest
#endif

@main
struct ReplAIApp: App {
    /// Owned here at the top so both the main app and environment share the same instances.
    @State private var usageTracker        = UsageTracker()
    @State private var subscriptionManager = SubscriptionManager()

    #if DEBUG
    /// Activates the bundled StoreKit.storekit catalogue at launch so that
    /// Product.products(for:) returns mock products on any device, even when
    /// the app is opened directly instead of via Xcode's Run command.
    /// The strong reference keeps the configuration alive for the app's lifetime.
    @State private var storeKitTestSession: SKTestSession? = nil
    #endif

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(usageTracker)
                .environment(subscriptionManager)
                .preferredColorScheme(.dark)
                .task {
                    #if DEBUG
                    // Must be created BEFORE loadProducts() so that StoreKit's
                    // environment is primed when Product.products(for:) fires.
                    if storeKitTestSession == nil {
                        storeKitTestSession = try? SKTestSession(
                            configurationFileNamed: "StoreKit"
                        )
                        // false = show standard purchase dialogs (not suppressed)
                        storeKitTestSession?.disableDialogs = false
                    }
                    #endif
                    await subscriptionManager.loadProducts()
                }
        }
    }
}
