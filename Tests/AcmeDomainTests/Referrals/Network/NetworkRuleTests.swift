@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkRuleTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newNetworkRule("code-800", title: "title-424")
        #expect(item.status == Referrals.NetworkRuleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Referrals.newNetworkRule("code-800", title: "title-424")
        try item.moveTo(Referrals.NetworkRuleStatus.draining)
        #expect(item.status == Referrals.NetworkRuleStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newNetworkRule("code-800", title: "title-424")
        item.status = Referrals.NetworkRuleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkRuleStatus.idle) }
    }
}
