@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedDispenseReviewTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newCappedDispenseReview("code-411", label: "label-346")
        #expect(item.status == Pharmacy.CappedDispenseReviewStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newCappedDispenseReview("code-411", label: "label-346")
        try item.moveTo(Pharmacy.CappedDispenseReviewStatus.approved)
        #expect(item.status == Pharmacy.CappedDispenseReviewStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newCappedDispenseReview("code-411", label: "label-346")
        item.status = Pharmacy.CappedDispenseReviewStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.CappedDispenseReviewStatus.proposed) }
    }
}
