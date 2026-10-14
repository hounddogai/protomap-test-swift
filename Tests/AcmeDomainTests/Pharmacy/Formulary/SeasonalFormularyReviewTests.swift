@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalFormularyReviewTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newSeasonalFormularyReview("code-466", title: "title-524")
        #expect(item.status == Pharmacy.SeasonalFormularyReviewStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newSeasonalFormularyReview("code-466", title: "title-524")
        try item.moveTo(Pharmacy.SeasonalFormularyReviewStatus.granted)
        #expect(item.status == Pharmacy.SeasonalFormularyReviewStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newSeasonalFormularyReview("code-466", title: "title-524")
        item.status = Pharmacy.SeasonalFormularyReviewStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SeasonalFormularyReviewStatus.requested) }
    }
}
