@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalRevocationAgreementTests {
    @Test func startsInDraft() throws {
        let item = Consent.newRegionalRevocationAgreement("code-823", label: "label-311")
        #expect(item.status == Consent.RegionalRevocationAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Consent.newRegionalRevocationAgreement("code-823", label: "label-311")
        try item.moveTo(Consent.RegionalRevocationAgreementStatus.closed)
        #expect(item.status == Consent.RegionalRevocationAgreementStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newRegionalRevocationAgreement("code-823", label: "label-311")
        item.status = Consent.RegionalRevocationAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RegionalRevocationAgreementStatus.draft) }
    }
}
