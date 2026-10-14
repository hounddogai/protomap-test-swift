@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingDisclosureAgreementTests {
    @Test func startsInCreated() throws {
        let item = Consent.newRollingDisclosureAgreement("code-294", title: "title-311")
        #expect(item.status == Consent.RollingDisclosureAgreementStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newRollingDisclosureAgreement("code-294", title: "title-311")
        try item.moveTo(Consent.RollingDisclosureAgreementStatus.validated)
        #expect(item.status == Consent.RollingDisclosureAgreementStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newRollingDisclosureAgreement("code-294", title: "title-311")
        item.status = Consent.RollingDisclosureAgreementStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingDisclosureAgreementStatus.created) }
    }
}
