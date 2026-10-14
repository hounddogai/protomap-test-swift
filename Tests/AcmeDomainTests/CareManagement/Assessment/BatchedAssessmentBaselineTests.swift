@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedAssessmentBaselineTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newBatchedAssessmentBaseline("code-905", label: "label-343")
        #expect(item.status == CareManagement.BatchedAssessmentBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newBatchedAssessmentBaseline("code-905", label: "label-343")
        try item.moveTo(CareManagement.BatchedAssessmentBaselineStatus.resolved)
        #expect(item.status == CareManagement.BatchedAssessmentBaselineStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newBatchedAssessmentBaseline("code-905", label: "label-343")
        item.status = CareManagement.BatchedAssessmentBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedAssessmentBaselineStatus.`open`) }
    }
}
