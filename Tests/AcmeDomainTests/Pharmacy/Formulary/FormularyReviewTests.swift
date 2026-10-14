@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyReviewTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newFormularyReview("code-484", label: "label-565")
        #expect(item.status == Pharmacy.FormularyReviewStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newFormularyReview("code-484", label: "label-565")
        try item.moveTo(Pharmacy.FormularyReviewStatus.granted)
        #expect(item.status == Pharmacy.FormularyReviewStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newFormularyReview("code-484", label: "label-565")
        item.status = Pharmacy.FormularyReviewStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyReviewStatus.requested) }
    }
}
