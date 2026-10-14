@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyRemittanceRuleTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newLegacyRemittanceRule("code-335", name: "name-173")
        #expect(item.status == RevenueCycle.LegacyRemittanceRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = RevenueCycle.newLegacyRemittanceRule("code-335", name: "name-173")
        try item.moveTo(RevenueCycle.LegacyRemittanceRuleStatus.failed)
        #expect(item.status == RevenueCycle.LegacyRemittanceRuleStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newLegacyRemittanceRule("code-335", name: "name-173")
        item.status = RevenueCycle.LegacyRemittanceRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LegacyRemittanceRuleStatus.new) }
    }
}
