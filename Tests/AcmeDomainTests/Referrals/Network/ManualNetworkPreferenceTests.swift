@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkPreferenceTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newManualNetworkPreference("code-669", title: "title-347")
        #expect(item.status == Referrals.ManualNetworkPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newManualNetworkPreference("code-669", title: "title-347")
        try item.moveTo(Referrals.ManualNetworkPreferenceStatus.ready)
        #expect(item.status == Referrals.ManualNetworkPreferenceStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newManualNetworkPreference("code-669", title: "title-347")
        item.status = Referrals.ManualNetworkPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualNetworkPreferenceStatus.idle) }
    }
}
