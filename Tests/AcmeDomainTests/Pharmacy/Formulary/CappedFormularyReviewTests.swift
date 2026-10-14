@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedFormularyReviewTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newCappedFormularyReview("code-164", title: "title-766")
        #expect(item.status == Pharmacy.CappedFormularyReviewStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newCappedFormularyReview("code-164", title: "title-766")
        try item.moveTo(Pharmacy.CappedFormularyReviewStatus.granted)
        #expect(item.status == Pharmacy.CappedFormularyReviewStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newCappedFormularyReview("code-164", title: "title-766")
        item.status = Pharmacy.CappedFormularyReviewStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.CappedFormularyReviewStatus.requested) }
    }
}
