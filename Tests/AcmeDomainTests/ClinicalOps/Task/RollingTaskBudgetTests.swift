@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingTaskBudgetTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newRollingTaskBudget("code-956", name: "name-650")
        #expect(item.status == ClinicalOps.RollingTaskBudgetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newRollingTaskBudget("code-956", name: "name-650")
        try item.moveTo(ClinicalOps.RollingTaskBudgetStatus.active)
        #expect(item.status == ClinicalOps.RollingTaskBudgetStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newRollingTaskBudget("code-956", name: "name-650")
        item.status = ClinicalOps.RollingTaskBudgetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RollingTaskBudgetStatus.draft) }
    }
}
