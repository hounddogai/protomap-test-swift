@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingBudgetTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newRoundingBudget("code-227", title: "title-346")
        #expect(item.status == ClinicalOps.RoundingBudgetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newRoundingBudget("code-227", title: "title-346")
        try item.moveTo(ClinicalOps.RoundingBudgetStatus.active)
        #expect(item.status == ClinicalOps.RoundingBudgetStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newRoundingBudget("code-227", title: "title-346")
        item.status = ClinicalOps.RoundingBudgetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingBudgetStatus.draft) }
    }
}
