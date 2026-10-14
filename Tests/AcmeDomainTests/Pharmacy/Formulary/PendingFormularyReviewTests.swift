@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingFormularyReviewTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newPendingFormularyReview("code-328", name: "name-26")
        #expect(item.status == Pharmacy.PendingFormularyReviewStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newPendingFormularyReview("code-328", name: "name-26")
        try item.moveTo(Pharmacy.PendingFormularyReviewStatus.published)
        #expect(item.status == Pharmacy.PendingFormularyReviewStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newPendingFormularyReview("code-328", name: "name-26")
        item.status = Pharmacy.PendingFormularyReviewStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingFormularyReviewStatus.created) }
    }
}
