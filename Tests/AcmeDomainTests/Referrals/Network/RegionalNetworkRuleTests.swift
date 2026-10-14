@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalNetworkRuleTests {
    @Test func startsInNew() throws {
        let item = Referrals.newRegionalNetworkRule("code-399", title: "title-759")
        #expect(item.status == Referrals.RegionalNetworkRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newRegionalNetworkRule("code-399", title: "title-759")
        try item.moveTo(Referrals.RegionalNetworkRuleStatus.running)
        #expect(item.status == Referrals.RegionalNetworkRuleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newRegionalNetworkRule("code-399", title: "title-759")
        item.status = Referrals.RegionalNetworkRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalNetworkRuleStatus.new) }
    }
}
