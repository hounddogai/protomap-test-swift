@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackDispenseReviewTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newFallbackDispenseReview("code-425", title: "title-94")
        #expect(item.status == Pharmacy.FallbackDispenseReviewStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Pharmacy.newFallbackDispenseReview("code-425", title: "title-94")
        try item.moveTo(Pharmacy.FallbackDispenseReviewStatus.completed)
        #expect(item.status == Pharmacy.FallbackDispenseReviewStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newFallbackDispenseReview("code-425", title: "title-94")
        item.status = Pharmacy.FallbackDispenseReviewStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FallbackDispenseReviewStatus.planned) }
    }
}
