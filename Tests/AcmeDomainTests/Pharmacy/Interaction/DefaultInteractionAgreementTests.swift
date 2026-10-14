@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionAgreementTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newDefaultInteractionAgreement("code-808", title: "title-359")
        #expect(item.status == Pharmacy.DefaultInteractionAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newDefaultInteractionAgreement("code-808", title: "title-359")
        try item.moveTo(Pharmacy.DefaultInteractionAgreementStatus.pending)
        #expect(item.status == Pharmacy.DefaultInteractionAgreementStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newDefaultInteractionAgreement("code-808", title: "title-359")
        item.status = Pharmacy.DefaultInteractionAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultInteractionAgreementStatus.draft) }
    }
}
