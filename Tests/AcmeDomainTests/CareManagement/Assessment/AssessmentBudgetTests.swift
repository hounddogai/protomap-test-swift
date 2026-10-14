@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentBudgetTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newAssessmentBudget("code-565", label: "label-188")
        #expect(item.status == CareManagement.AssessmentBudgetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newAssessmentBudget("code-565", label: "label-188")
        try item.moveTo(CareManagement.AssessmentBudgetStatus.validated)
        #expect(item.status == CareManagement.AssessmentBudgetStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newAssessmentBudget("code-565", label: "label-188")
        item.status = CareManagement.AssessmentBudgetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentBudgetStatus.created) }
    }
}
