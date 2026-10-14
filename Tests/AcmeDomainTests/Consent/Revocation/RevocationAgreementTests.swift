@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationAgreementTests {
    @Test func startsInRequested() throws {
        let item = Consent.newRevocationAgreement("code-273", label: "label-170")
        #expect(item.status == Consent.RevocationAgreementStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newRevocationAgreement("code-273", label: "label-170")
        try item.moveTo(Consent.RevocationAgreementStatus.revoked)
        #expect(item.status == Consent.RevocationAgreementStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newRevocationAgreement("code-273", label: "label-170")
        item.status = Consent.RevocationAgreementStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationAgreementStatus.requested) }
    }
}
