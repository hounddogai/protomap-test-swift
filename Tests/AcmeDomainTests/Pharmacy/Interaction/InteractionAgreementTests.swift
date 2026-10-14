@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionAgreementTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newInteractionAgreement("code-219", label: "label-498")
        #expect(item.status == Pharmacy.InteractionAgreementStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newInteractionAgreement("code-219", label: "label-498")
        try item.moveTo(Pharmacy.InteractionAgreementStatus.inReview)
        #expect(item.status == Pharmacy.InteractionAgreementStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newInteractionAgreement("code-219", label: "label-498")
        item.status = Pharmacy.InteractionAgreementStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionAgreementStatus.`open`) }
    }
}
