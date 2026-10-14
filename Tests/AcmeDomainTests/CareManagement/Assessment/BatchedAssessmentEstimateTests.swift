@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedAssessmentEstimateTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newBatchedAssessmentEstimate("code-848", label: "label-821")
        #expect(item.status == CareManagement.BatchedAssessmentEstimateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newBatchedAssessmentEstimate("code-848", label: "label-821")
        try item.moveTo(CareManagement.BatchedAssessmentEstimateStatus.pending)
        #expect(item.status == CareManagement.BatchedAssessmentEstimateStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newBatchedAssessmentEstimate("code-848", label: "label-821")
        item.status = CareManagement.BatchedAssessmentEstimateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedAssessmentEstimateStatus.draft) }
    }
}
