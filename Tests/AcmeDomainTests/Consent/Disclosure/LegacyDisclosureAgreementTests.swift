@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyDisclosureAgreementTests {
    @Test func startsInNew() throws {
        let item = Consent.newLegacyDisclosureAgreement("code-873", title: "title-840")
        #expect(item.status == Consent.LegacyDisclosureAgreementStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newLegacyDisclosureAgreement("code-873", title: "title-840")
        try item.moveTo(Consent.LegacyDisclosureAgreementStatus.running)
        #expect(item.status == Consent.LegacyDisclosureAgreementStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newLegacyDisclosureAgreement("code-873", title: "title-840")
        item.status = Consent.LegacyDisclosureAgreementStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LegacyDisclosureAgreementStatus.new) }
    }
}
