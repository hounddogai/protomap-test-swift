@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingCareGapReviewTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newRollingCareGapReview("code-396", title: "title-516")
        #expect(item.status == CareManagement.RollingCareGapReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newRollingCareGapReview("code-396", title: "title-516")
        try item.moveTo(CareManagement.RollingCareGapReviewStatus.reopened)
        #expect(item.status == CareManagement.RollingCareGapReviewStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newRollingCareGapReview("code-396", title: "title-516")
        item.status = CareManagement.RollingCareGapReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RollingCareGapReviewStatus.`open`) }
    }
}
