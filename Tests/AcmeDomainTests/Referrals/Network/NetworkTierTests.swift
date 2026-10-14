@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkTierTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newNetworkTier("code-20", title: "title-847")
        #expect(item.status == Referrals.NetworkTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newNetworkTier("code-20", title: "title-847")
        try item.moveTo(Referrals.NetworkTierStatus.scheduled)
        #expect(item.status == Referrals.NetworkTierStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newNetworkTier("code-20", title: "title-847")
        item.status = Referrals.NetworkTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkTierStatus.planned) }
    }
}
