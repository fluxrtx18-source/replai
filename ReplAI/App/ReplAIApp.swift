import SwiftUI

@main
struct ReplAIApp: App {
    /// Owned here at the top so both the main app and environment share the same instances.
    @State private var usageTracker        = UsageTracker()
    @State private var subscriptionManager = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(usageTracker)
                .environment(subscriptionManager)
                .preferredColorScheme(.dark)
                .task {
                    await subscriptionManager.loadProducts()
                }
        }
    }
}
