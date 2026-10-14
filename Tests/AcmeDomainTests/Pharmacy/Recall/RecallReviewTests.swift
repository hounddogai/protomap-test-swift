@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallReviewTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newRecallReview("code-565", name: "name-767")
        #expect(item.status == Pharmacy.RecallReviewStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newRecallReview("code-565", name: "name-767")
        try item.moveTo(Pharmacy.RecallReviewStatus.queued)
        #expect(item.status == Pharmacy.RecallReviewStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newRecallReview("code-565", name: "name-767")
        item.status = Pharmacy.RecallReviewStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallReviewStatus.new) }
    }
}
