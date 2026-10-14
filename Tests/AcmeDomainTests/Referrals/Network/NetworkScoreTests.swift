@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkScoreTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newNetworkScore("code-631", title: "title-810")
        #expect(item.status == Referrals.NetworkScoreStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Referrals.newNetworkScore("code-631", title: "title-810")
        try item.moveTo(Referrals.NetworkScoreStatus.revoked)
        #expect(item.status == Referrals.NetworkScoreStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newNetworkScore("code-631", title: "title-810")
        item.status = Referrals.NetworkScoreStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkScoreStatus.requested) }
    }
}
