@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictRecallReviewTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newStrictRecallReview("code-784", label: "label-77")
        #expect(item.status == Pharmacy.StrictRecallReviewStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newStrictRecallReview("code-784", label: "label-77")
        try item.moveTo(Pharmacy.StrictRecallReviewStatus.inProgress)
        #expect(item.status == Pharmacy.StrictRecallReviewStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newStrictRecallReview("code-784", label: "label-77")
        item.status = Pharmacy.StrictRecallReviewStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.StrictRecallReviewStatus.planned) }
    }
}
