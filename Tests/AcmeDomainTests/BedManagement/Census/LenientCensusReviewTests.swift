@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusReviewTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newLenientCensusReview("code-297", label: "label-430")
        #expect(item.status == BedManagement.LenientCensusReviewStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newLenientCensusReview("code-297", label: "label-430")
        try item.moveTo(BedManagement.LenientCensusReviewStatus.scheduled)
        #expect(item.status == BedManagement.LenientCensusReviewStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newLenientCensusReview("code-297", label: "label-430")
        item.status = BedManagement.LenientCensusReviewStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientCensusReviewStatus.planned) }
    }
}
