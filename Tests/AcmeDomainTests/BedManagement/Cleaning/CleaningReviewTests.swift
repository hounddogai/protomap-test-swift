@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningReviewTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newCleaningReview("code-661", name: "name-632")
        #expect(item.status == BedManagement.CleaningReviewStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = BedManagement.newCleaningReview("code-661", name: "name-632")
        try item.moveTo(BedManagement.CleaningReviewStatus.stopped)
        #expect(item.status == BedManagement.CleaningReviewStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newCleaningReview("code-661", name: "name-632")
        item.status = BedManagement.CleaningReviewStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningReviewStatus.idle) }
    }
}
