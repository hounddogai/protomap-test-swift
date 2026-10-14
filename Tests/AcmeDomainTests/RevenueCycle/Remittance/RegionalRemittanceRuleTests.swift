@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalRemittanceRuleTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newRegionalRemittanceRule("code-942", label: "label-989")
        #expect(item.status == RevenueCycle.RegionalRemittanceRuleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = RevenueCycle.newRegionalRemittanceRule("code-942", label: "label-989")
        try item.moveTo(RevenueCycle.RegionalRemittanceRuleStatus.closed)
        #expect(item.status == RevenueCycle.RegionalRemittanceRuleStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newRegionalRemittanceRule("code-942", label: "label-989")
        item.status = RevenueCycle.RegionalRemittanceRuleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RegionalRemittanceRuleStatus.draft) }
    }
}
