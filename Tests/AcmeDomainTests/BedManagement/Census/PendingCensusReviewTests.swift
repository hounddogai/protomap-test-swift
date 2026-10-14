@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCensusReviewTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newPendingCensusReview("code-953", title: "title-646")
        #expect(item.status == BedManagement.PendingCensusReviewStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newPendingCensusReview("code-953", title: "title-646")
        try item.moveTo(BedManagement.PendingCensusReviewStatus.queued)
        #expect(item.status == BedManagement.PendingCensusReviewStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newPendingCensusReview("code-953", title: "title-646")
        item.status = BedManagement.PendingCensusReviewStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PendingCensusReviewStatus.new) }
    }
}
