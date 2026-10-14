@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedStatementBudgetTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newBatchedStatementBudget("code-831", name: "name-254")
        #expect(item.status == RevenueCycle.BatchedStatementBudgetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newBatchedStatementBudget("code-831", name: "name-254")
        try item.moveTo(RevenueCycle.BatchedStatementBudgetStatus.validated)
        #expect(item.status == RevenueCycle.BatchedStatementBudgetStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newBatchedStatementBudget("code-831", name: "name-254")
        item.status = RevenueCycle.BatchedStatementBudgetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedStatementBudgetStatus.created) }
    }
}
