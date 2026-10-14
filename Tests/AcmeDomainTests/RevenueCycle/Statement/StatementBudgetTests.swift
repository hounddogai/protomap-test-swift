@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementBudgetTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newStatementBudget("code-697", title: "title-84")
        #expect(item.status == RevenueCycle.StatementBudgetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = RevenueCycle.newStatementBudget("code-697", title: "title-84")
        try item.moveTo(RevenueCycle.StatementBudgetStatus.rejected)
        #expect(item.status == RevenueCycle.StatementBudgetStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newStatementBudget("code-697", title: "title-84")
        item.status = RevenueCycle.StatementBudgetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementBudgetStatus.proposed) }
    }
}
