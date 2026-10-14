@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedConsentFormNoticeTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newCappedConsentFormNotice("code-154", title: "title-271")
        #expect(item.status == Consent.CappedConsentFormNoticeStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Consent.newCappedConsentFormNotice("code-154", title: "title-271")
        try item.moveTo(Consent.CappedConsentFormNoticeStatus.cancelled)
        #expect(item.status == Consent.CappedConsentFormNoticeStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newCappedConsentFormNotice("code-154", title: "title-271")
        item.status = Consent.CappedConsentFormNoticeStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedConsentFormNoticeStatus.planned) }
    }
}
