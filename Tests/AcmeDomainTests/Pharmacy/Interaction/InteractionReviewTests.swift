@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionReviewTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newInteractionReview("code-84", label: "label-306")
        #expect(item.status == Pharmacy.InteractionReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newInteractionReview("code-84", label: "label-306")
        try item.moveTo(Pharmacy.InteractionReviewStatus.reopened)
        #expect(item.status == Pharmacy.InteractionReviewStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newInteractionReview("code-84", label: "label-306")
        item.status = Pharmacy.InteractionReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionReviewStatus.`open`) }
    }
}
