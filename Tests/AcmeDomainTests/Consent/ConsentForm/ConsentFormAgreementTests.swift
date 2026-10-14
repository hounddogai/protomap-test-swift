@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormAgreementTests {
    @Test func startsInCreated() throws {
        let item = Consent.newConsentFormAgreement("code-923", name: "name-19")
        #expect(item.status == Consent.ConsentFormAgreementStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newConsentFormAgreement("code-923", name: "name-19")
        try item.moveTo(Consent.ConsentFormAgreementStatus.validated)
        #expect(item.status == Consent.ConsentFormAgreementStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newConsentFormAgreement("code-923", name: "name-19")
        item.status = Consent.ConsentFormAgreementStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormAgreementStatus.created) }
    }
}
