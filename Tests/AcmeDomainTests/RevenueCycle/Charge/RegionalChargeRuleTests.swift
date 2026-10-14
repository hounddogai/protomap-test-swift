@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalChargeRuleTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newRegionalChargeRule("code-161", title: "title-473")
        #expect(item.status == RevenueCycle.RegionalChargeRuleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newRegionalChargeRule("code-161", title: "title-473")
        try item.moveTo(RevenueCycle.RegionalChargeRuleStatus.revoked)
        #expect(item.status == RevenueCycle.RegionalChargeRuleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newRegionalChargeRule("code-161", title: "title-473")
        item.status = RevenueCycle.RegionalChargeRuleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RegionalChargeRuleStatus.requested) }
    }
}
