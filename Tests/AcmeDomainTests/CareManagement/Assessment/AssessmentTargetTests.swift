@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentTargetTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newAssessmentTarget("code-468", label: "label-663")
        #expect(item.status == CareManagement.AssessmentTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newAssessmentTarget("code-468", label: "label-663")
        try item.moveTo(CareManagement.AssessmentTargetStatus.reopened)
        #expect(item.status == CareManagement.AssessmentTargetStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newAssessmentTarget("code-468", label: "label-663")
        item.status = CareManagement.AssessmentTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentTargetStatus.`open`) }
    }
}
