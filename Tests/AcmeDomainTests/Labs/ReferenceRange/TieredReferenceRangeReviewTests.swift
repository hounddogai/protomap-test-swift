@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredReferenceRangeReviewTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newTieredReferenceRangeReview("code-174", label: "label-366")
        #expect(item.status == Labs.TieredReferenceRangeReviewStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Labs.newTieredReferenceRangeReview("code-174", label: "label-366")
        try item.moveTo(Labs.TieredReferenceRangeReviewStatus.inProgress)
        #expect(item.status == Labs.TieredReferenceRangeReviewStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newTieredReferenceRangeReview("code-174", label: "label-366")
        item.status = Labs.TieredReferenceRangeReviewStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.TieredReferenceRangeReviewStatus.planned) }
    }
}
