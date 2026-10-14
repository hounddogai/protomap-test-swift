@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualConsentFormNoticeTests {
    @Test func startsInCreated() throws {
        let item = Consent.newManualConsentFormNotice("code-53", label: "label-481")
        #expect(item.status == Consent.ManualConsentFormNoticeStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newManualConsentFormNotice("code-53", label: "label-481")
        try item.moveTo(Consent.ManualConsentFormNoticeStatus.validated)
        #expect(item.status == Consent.ManualConsentFormNoticeStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newManualConsentFormNotice("code-53", label: "label-481")
        item.status = Consent.ManualConsentFormNoticeStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ManualConsentFormNoticeStatus.created) }
    }
}
