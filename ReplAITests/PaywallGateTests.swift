import Testing
@testable import ReplAI

// MARK: - PaywallGate Tests
//
// These tests guard the D1 (tone locking) and D2 (summary locking) product
// invariants. A regression in PaywallGate would silently give away paid
// features to free users, so coverage here is treated as a hard blocker.

@Suite("PaywallGate")
struct PaywallGateTests {

    // MARK: - D1: Tone locking — free user

    @Test("Free user: the Calm tone is unlocked (free tier)")
    func freeUserCalmIsUnlocked() {
        #expect(!PaywallGate.isLocked(tone: .calm, isSubscribed: false))
    }

    @Test("Free user: every non-Calm tone is locked",
          arguments: ReplyTone.allCases.filter { $0 != PaywallGate.freeTone })
    func freeUserNonCalmIsLocked(tone: ReplyTone) {
        #expect(PaywallGate.isLocked(tone: tone, isSubscribed: false))
    }

    @Test("Free user: exactly one tone is free")
    func exactlyOneFreeTone() {
        let free = ReplyTone.allCases.filter { !PaywallGate.isLocked(tone: $0, isSubscribed: false) }
        #expect(free.count == 1)
    }

    @Test("Free user: the single free tone is PaywallGate.freeTone")
    func freeToneMatchesConstant() {
        let free = ReplyTone.allCases.filter { !PaywallGate.isLocked(tone: $0, isSubscribed: false) }
        #expect(free == [PaywallGate.freeTone])
    }

    @Test("Free user: exactly 5 tones are locked (all except freeTone)")
    func fiveLockedTonesForFreeUser() {
        let locked = ReplyTone.allCases.filter { PaywallGate.isLocked(tone: $0, isSubscribed: false) }
        #expect(locked.count == ReplyTone.allCases.count - 1)
    }

    // MARK: - D1: Tone locking — subscribed user

    @Test("Subscribed user: no tones are locked", arguments: ReplyTone.allCases)
    func subscribedUserAllTonesUnlocked(tone: ReplyTone) {
        #expect(!PaywallGate.isLocked(tone: tone, isSubscribed: true))
    }

    @Test("Subscribed user: zero locked tones in allCases")
    func subscribedUserLockedCountIsZero() {
        let locked = ReplyTone.allCases.filter { PaywallGate.isLocked(tone: $0, isSubscribed: true) }
        #expect(locked.isEmpty)
    }

    // MARK: - D1: freeTone constant integrity

    @Test("PaywallGate.freeTone is .calm (the configured free tier)")
    func freeToneIsCalm() {
        #expect(PaywallGate.freeTone == .calm)
    }

    @Test("freeTone is always unlocked for a free user")
    func freeToneConstantIsUnlocked() {
        #expect(!PaywallGate.isLocked(tone: PaywallGate.freeTone, isSubscribed: false))
    }

    // MARK: - D2: Summary locking — free user

    @Test("Free user: emotional summary is locked (D2)")
    func freeUserSummaryIsLocked() {
        #expect(PaywallGate.isSummaryLocked(isSubscribed: false))
    }

    // MARK: - D2: Summary locking — subscribed user

    @Test("Subscribed user: emotional summary is unlocked (D2)")
    func subscribedUserSummaryIsUnlocked() {
        #expect(!PaywallGate.isSummaryLocked(isSubscribed: true))
    }

    // MARK: - Regression guards

    @Test("Tone gate and summary gate agree on subscription state")
    func gatesAreConsistentForSubscriber() {
        // A subscribed user should have both gates open.
        let noLockedTones = ReplyTone.allCases.allSatisfy {
            !PaywallGate.isLocked(tone: $0, isSubscribed: true)
        }
        #expect(noLockedTones)
        #expect(!PaywallGate.isSummaryLocked(isSubscribed: true))
    }

    @Test("Tone gate and summary gate agree on free user state")
    func gatesAreConsistentForFreeUser() {
        // A free user should have the summary locked and only freeTone unlocked.
        #expect(PaywallGate.isSummaryLocked(isSubscribed: false))
        #expect(!PaywallGate.isLocked(tone: PaywallGate.freeTone, isSubscribed: false))
    }

    @Test("isLocked is purely determined by subscription state and tone — no side effects",
          arguments: [true, false])
    func isLockedIsPure(isSubscribed: Bool) {
        // Calling isLocked twice with the same inputs must return the same result.
        for tone in ReplyTone.allCases {
            let first  = PaywallGate.isLocked(tone: tone, isSubscribed: isSubscribed)
            let second = PaywallGate.isLocked(tone: tone, isSubscribed: isSubscribed)
            #expect(first == second)
        }
    }
}
