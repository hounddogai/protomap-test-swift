@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertBudgetTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newAlertBudget("code-526", title: "title-353")
        #expect(item.status == ClinicalOps.AlertBudgetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = ClinicalOps.newAlertBudget("code-526", title: "title-353")
        try item.moveTo(ClinicalOps.AlertBudgetStatus.rejected)
        #expect(item.status == ClinicalOps.AlertBudgetStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newAlertBudget("code-526", title: "title-353")
        item.status = ClinicalOps.AlertBudgetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertBudgetStatus.proposed) }
    }
}
