@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentReviewTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newAssessmentReview("code-922", title: "title-998")
        #expect(item.status == CareManagement.AssessmentReviewStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = CareManagement.newAssessmentReview("code-922", title: "title-998")
        try item.moveTo(CareManagement.AssessmentReviewStatus.draining)
        #expect(item.status == CareManagement.AssessmentReviewStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newAssessmentReview("code-922", title: "title-998")
        item.status = CareManagement.AssessmentReviewStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentReviewStatus.idle) }
    }
}
