@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingGoalReviewTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newPendingGoalReview("code-173", label: "label-584")
        #expect(item.status == CareManagement.PendingGoalReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newPendingGoalReview("code-173", label: "label-584")
        try item.moveTo(CareManagement.PendingGoalReviewStatus.inReview)
        #expect(item.status == CareManagement.PendingGoalReviewStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newPendingGoalReview("code-173", label: "label-584")
        item.status = CareManagement.PendingGoalReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingGoalReviewStatus.`open`) }
    }
}
