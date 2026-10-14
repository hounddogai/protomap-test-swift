@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialRuleTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newDenialRule("code-75", name: "name-220")
        #expect(item.status == RevenueCycle.DenialRuleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = RevenueCycle.newDenialRule("code-75", name: "name-220")
        try item.moveTo(RevenueCycle.DenialRuleStatus.inProgress)
        #expect(item.status == RevenueCycle.DenialRuleStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newDenialRule("code-75", name: "name-220")
        item.status = RevenueCycle.DenialRuleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialRuleStatus.planned) }
    }
}
