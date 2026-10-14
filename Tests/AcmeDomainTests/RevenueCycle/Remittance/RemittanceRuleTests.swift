@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceRuleTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newRemittanceRule("code-307", title: "title-724")
        #expect(item.status == RevenueCycle.RemittanceRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = RevenueCycle.newRemittanceRule("code-307", title: "title-724")
        try item.moveTo(RevenueCycle.RemittanceRuleStatus.done)
        #expect(item.status == RevenueCycle.RemittanceRuleStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newRemittanceRule("code-307", title: "title-724")
        item.status = RevenueCycle.RemittanceRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceRuleStatus.new) }
    }
}
