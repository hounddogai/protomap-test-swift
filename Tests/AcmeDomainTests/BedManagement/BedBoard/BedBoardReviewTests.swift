@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardReviewTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newBedBoardReview("code-505", name: "name-521")
        #expect(item.status == BedManagement.BedBoardReviewStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newBedBoardReview("code-505", name: "name-521")
        try item.moveTo(BedManagement.BedBoardReviewStatus.queued)
        #expect(item.status == BedManagement.BedBoardReviewStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newBedBoardReview("code-505", name: "name-521")
        item.status = BedManagement.BedBoardReviewStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardReviewStatus.new) }
    }
}
