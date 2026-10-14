@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingNetworkPreferenceTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newPendingNetworkPreference("code-85", title: "title-701")
        #expect(item.status == Referrals.PendingNetworkPreferenceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Referrals.newPendingNetworkPreference("code-85", title: "title-701")
        try item.moveTo(Referrals.PendingNetworkPreferenceStatus.expired)
        #expect(item.status == Referrals.PendingNetworkPreferenceStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newPendingNetworkPreference("code-85", title: "title-701")
        item.status = Referrals.PendingNetworkPreferenceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PendingNetworkPreferenceStatus.requested) }
    }
}
