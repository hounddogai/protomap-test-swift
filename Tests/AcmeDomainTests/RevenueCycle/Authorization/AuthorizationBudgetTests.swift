@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationBudgetTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newAuthorizationBudget("code-45", label: "label-483")
        #expect(item.status == RevenueCycle.AuthorizationBudgetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newAuthorizationBudget("code-45", label: "label-483")
        try item.moveTo(RevenueCycle.AuthorizationBudgetStatus.warming)
        #expect(item.status == RevenueCycle.AuthorizationBudgetStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newAuthorizationBudget("code-45", label: "label-483")
        item.status = RevenueCycle.AuthorizationBudgetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationBudgetStatus.idle) }
    }
}
