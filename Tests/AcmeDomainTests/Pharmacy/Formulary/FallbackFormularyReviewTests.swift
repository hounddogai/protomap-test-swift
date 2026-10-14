@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackFormularyReviewTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newFallbackFormularyReview("code-408", name: "name-158")
        #expect(item.status == Pharmacy.FallbackFormularyReviewStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newFallbackFormularyReview("code-408", name: "name-158")
        try item.moveTo(Pharmacy.FallbackFormularyReviewStatus.approved)
        #expect(item.status == Pharmacy.FallbackFormularyReviewStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newFallbackFormularyReview("code-408", name: "name-158")
        item.status = Pharmacy.FallbackFormularyReviewStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FallbackFormularyReviewStatus.proposed) }
    }
}
