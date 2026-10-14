@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackAssessmentAssignmentTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newFallbackAssessmentAssignment("code-771", title: "title-84")
        #expect(item.status == CareManagement.FallbackAssessmentAssignmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newFallbackAssessmentAssignment("code-771", title: "title-84")
        try item.moveTo(CareManagement.FallbackAssessmentAssignmentStatus.inReview)
        #expect(item.status == CareManagement.FallbackAssessmentAssignmentStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newFallbackAssessmentAssignment("code-771", title: "title-84")
        item.status = CareManagement.FallbackAssessmentAssignmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.FallbackAssessmentAssignmentStatus.`open`) }
    }
}
