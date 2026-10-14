@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeRuleTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newChargeRule("code-104", title: "title-769")
        #expect(item.status == RevenueCycle.ChargeRuleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newChargeRule("code-104", title: "title-769")
        try item.moveTo(RevenueCycle.ChargeRuleStatus.scheduled)
        #expect(item.status == RevenueCycle.ChargeRuleStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newChargeRule("code-104", title: "title-769")
        item.status = RevenueCycle.ChargeRuleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeRuleStatus.planned) }
    }
}
