@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeBudgetTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newChargeBudget("code-436", name: "name-195")
        #expect(item.status == RevenueCycle.ChargeBudgetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newChargeBudget("code-436", name: "name-195")
        try item.moveTo(RevenueCycle.ChargeBudgetStatus.suspended)
        #expect(item.status == RevenueCycle.ChargeBudgetStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newChargeBudget("code-436", name: "name-195")
        item.status = RevenueCycle.ChargeBudgetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeBudgetStatus.draft) }
    }
}
