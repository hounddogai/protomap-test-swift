@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedAssessmentBudgetTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newWeightedAssessmentBudget("code-888", title: "title-761")
        #expect(item.status == CareManagement.WeightedAssessmentBudgetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newWeightedAssessmentBudget("code-888", title: "title-761")
        try item.moveTo(CareManagement.WeightedAssessmentBudgetStatus.active)
        #expect(item.status == CareManagement.WeightedAssessmentBudgetStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newWeightedAssessmentBudget("code-888", title: "title-761")
        item.status = CareManagement.WeightedAssessmentBudgetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedAssessmentBudgetStatus.draft) }
    }
}
