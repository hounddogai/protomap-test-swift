@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimBudgetTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newClaimBudget("code-649", title: "title-636")
        #expect(item.status == RevenueCycle.ClaimBudgetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = RevenueCycle.newClaimBudget("code-649", title: "title-636")
        try item.moveTo(RevenueCycle.ClaimBudgetStatus.draining)
        #expect(item.status == RevenueCycle.ClaimBudgetStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newClaimBudget("code-649", title: "title-636")
        item.status = RevenueCycle.ClaimBudgetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimBudgetStatus.idle) }
    }
}
