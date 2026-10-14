@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionClaimTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newInteractionClaim("code-274", title: "title-915")
        #expect(item.status == Pharmacy.InteractionClaimStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newInteractionClaim("code-274", title: "title-915")
        try item.moveTo(Pharmacy.InteractionClaimStatus.inReview)
        #expect(item.status == Pharmacy.InteractionClaimStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newInteractionClaim("code-274", title: "title-915")
        item.status = Pharmacy.InteractionClaimStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionClaimStatus.`open`) }
    }
}
