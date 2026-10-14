@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultNetworkRuleTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newDefaultNetworkRule("code-277", label: "label-953")
        #expect(item.status == Referrals.DefaultNetworkRuleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newDefaultNetworkRule("code-277", label: "label-953")
        try item.moveTo(Referrals.DefaultNetworkRuleStatus.approved)
        #expect(item.status == Referrals.DefaultNetworkRuleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newDefaultNetworkRule("code-277", label: "label-953")
        item.status = Referrals.DefaultNetworkRuleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.DefaultNetworkRuleStatus.proposed) }
    }
}
