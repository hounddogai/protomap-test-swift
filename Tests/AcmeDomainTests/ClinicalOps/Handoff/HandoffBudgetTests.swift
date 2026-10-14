@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffBudgetTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newHandoffBudget("code-248", name: "name-92")
        #expect(item.status == ClinicalOps.HandoffBudgetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newHandoffBudget("code-248", name: "name-92")
        try item.moveTo(ClinicalOps.HandoffBudgetStatus.suspended)
        #expect(item.status == ClinicalOps.HandoffBudgetStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newHandoffBudget("code-248", name: "name-92")
        item.status = ClinicalOps.HandoffBudgetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffBudgetStatus.draft) }
    }
}
