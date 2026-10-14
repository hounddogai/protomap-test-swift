@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveDispenseReviewTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newAdaptiveDispenseReview("code-906", label: "label-529")
        #expect(item.status == Pharmacy.AdaptiveDispenseReviewStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newAdaptiveDispenseReview("code-906", label: "label-529")
        try item.moveTo(Pharmacy.AdaptiveDispenseReviewStatus.approved)
        #expect(item.status == Pharmacy.AdaptiveDispenseReviewStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newAdaptiveDispenseReview("code-906", label: "label-529")
        item.status = Pharmacy.AdaptiveDispenseReviewStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.AdaptiveDispenseReviewStatus.proposed) }
    }
}
