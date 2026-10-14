@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientLanguageAgreementTests {
    @Test func startsInDraft() throws {
        let item = Consent.newLenientLanguageAgreement("code-857", title: "title-49")
        #expect(item.status == Consent.LenientLanguageAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newLenientLanguageAgreement("code-857", title: "title-49")
        try item.moveTo(Consent.LenientLanguageAgreementStatus.pending)
        #expect(item.status == Consent.LenientLanguageAgreementStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newLenientLanguageAgreement("code-857", title: "title-49")
        item.status = Consent.LenientLanguageAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientLanguageAgreementStatus.draft) }
    }
}
