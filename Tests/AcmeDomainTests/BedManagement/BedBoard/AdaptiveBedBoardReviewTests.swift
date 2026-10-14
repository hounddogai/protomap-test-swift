@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveBedBoardReviewTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newAdaptiveBedBoardReview("code-328", name: "name-628")
        #expect(item.status == BedManagement.AdaptiveBedBoardReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = BedManagement.newAdaptiveBedBoardReview("code-328", name: "name-628")
        try item.moveTo(BedManagement.AdaptiveBedBoardReviewStatus.reopened)
        #expect(item.status == BedManagement.AdaptiveBedBoardReviewStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newAdaptiveBedBoardReview("code-328", name: "name-628")
        item.status = BedManagement.AdaptiveBedBoardReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveBedBoardReviewStatus.`open`) }
    }
}
