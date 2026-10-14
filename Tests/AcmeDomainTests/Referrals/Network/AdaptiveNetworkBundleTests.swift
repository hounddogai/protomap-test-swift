@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveNetworkBundleTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newAdaptiveNetworkBundle("code-457", title: "title-31")
        #expect(item.status == Referrals.AdaptiveNetworkBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newAdaptiveNetworkBundle("code-457", title: "title-31")
        try item.moveTo(Referrals.AdaptiveNetworkBundleStatus.ready)
        #expect(item.status == Referrals.AdaptiveNetworkBundleStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newAdaptiveNetworkBundle("code-457", title: "title-31")
        item.status = Referrals.AdaptiveNetworkBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.AdaptiveNetworkBundleStatus.idle) }
    }
}
