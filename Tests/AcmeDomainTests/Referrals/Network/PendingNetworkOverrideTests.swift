@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingNetworkOverrideTests {
    @Test func startsInNew() throws {
        let item = Referrals.newPendingNetworkOverride("code-18", name: "name-673")
        #expect(item.status == Referrals.PendingNetworkOverrideStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newPendingNetworkOverride("code-18", name: "name-673")
        try item.moveTo(Referrals.PendingNetworkOverrideStatus.running)
        #expect(item.status == Referrals.PendingNetworkOverrideStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newPendingNetworkOverride("code-18", name: "name-673")
        item.status = Referrals.PendingNetworkOverrideStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PendingNetworkOverrideStatus.new) }
    }
}
