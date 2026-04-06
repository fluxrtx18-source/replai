import SwiftUI

struct HomeView: View {
    @Environment(UsageTracker.self)        private var usageTracker
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var selectedImage: IdentifiableImage?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppDesign.Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppDesign.Spacing.xl) {
                        HomeHeaderView()
                        // Badge only shown for free users — subscribers don't need the nudge.
                        if !subscriptionManager.isSubscribed {
                            UsageBadgeView()
                        }
                        HowItWorksCard()
                        HomeActionSection(
                            onImage: { selectedImage = IdentifiableImage(image: $0) }
                        )
                        Spacer(minLength: AppDesign.Spacing.xxl)
                    }
                    .padding(AppDesign.Spacing.md)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !subscriptionManager.isSubscribed {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Upgrade", action: openPaywall)
                            .font(AppDesign.Font.subhead)
                            .foregroundStyle(AppDesign.Color.accent)
                    }
                }
            }
            .sheet(item: $selectedImage) { wrapper in
                AnalysisView(image: wrapper.image)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onOpenURL(perform: handleIncomingURL)
            .onForeground {
                usageTracker.refresh()
                // Refresh subscription status on every foreground transition.
                // Covers the case where a subscription expired while backgrounded —
                // Transaction.updates handles new purchases but not immediate expiry.
                Task { await subscriptionManager.refresh() }
            }
        }
    }

    // MARK: - Helpers

    private func openPaywall() {
        showPaywall = true
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "replai" else { return }
        switch url.host {
        case "analyze":
            // Consume the one-time nonce written by the Share Extension.
            // Absent nonce means a third-party app sent the URL — discard it.
            let defaults = UserDefaults(suiteName: AppDesign.appGroupID)
            guard defaults?.string(forKey: AppDesign.pendingNonceKey) != nil else { return }
            defaults?.removeObject(forKey: AppDesign.pendingNonceKey)
            loadSharedImage()
        case "paywall":
            // Opened by the Action Extension when the user taps an upgrade prompt.
            openPaywall()
        default:
            break
        }
    }

    private func loadSharedImage() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppDesign.appGroupID
        ) else { return }

        let fileURL = containerURL.appendingPathComponent(AppDesign.pendingImageFilename)

        // Discard images written more than 2 minutes ago — likely stale from a session
        // where the share extension wrote the file but the main app never launched.
        let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        if let created = attrs?[.creationDate] as? Date,
           Date.now.timeIntervalSince(created) > 120 {
            try? FileManager.default.removeItem(at: fileURL)
            return
        }

        guard let data  = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else { return }

        // Remove only after successful decode to prevent data loss
        try? FileManager.default.removeItem(at: fileURL)
        selectedImage = IdentifiableImage(image: image)
    }
}

// MARK: - Foreground detection helper

private extension View {
    func onForeground(perform action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            action()
        }
    }
}

#Preview {
    HomeView()
        .environment(UsageTracker())
        .environment(SubscriptionManager())
}
