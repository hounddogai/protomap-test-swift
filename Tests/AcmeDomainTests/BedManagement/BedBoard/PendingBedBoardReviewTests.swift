@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingBedBoardReviewTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newPendingBedBoardReview("code-26", label: "label-578")
        #expect(item.status == BedManagement.PendingBedBoardReviewStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newPendingBedBoardReview("code-26", label: "label-578")
        try item.moveTo(BedManagement.PendingBedBoardReviewStatus.warming)
        #expect(item.status == BedManagement.PendingBedBoardReviewStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newPendingBedBoardReview("code-26", label: "label-578")
        item.status = BedManagement.PendingBedBoardReviewStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PendingBedBoardReviewStatus.idle) }
    }
}
