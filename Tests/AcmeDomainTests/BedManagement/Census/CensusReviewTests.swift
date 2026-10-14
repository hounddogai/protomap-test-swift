@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusReviewTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newCensusReview("code-305", name: "name-707")
        #expect(item.status == BedManagement.CensusReviewStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newCensusReview("code-305", name: "name-707")
        try item.moveTo(BedManagement.CensusReviewStatus.active)
        #expect(item.status == BedManagement.CensusReviewStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newCensusReview("code-305", name: "name-707")
        item.status = BedManagement.CensusReviewStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusReviewStatus.draft) }
    }
}
