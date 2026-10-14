@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormNoticeTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newConsentFormNotice("code-914", name: "name-749")
        #expect(item.status == Consent.ConsentFormNoticeStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Consent.newConsentFormNotice("code-914", name: "name-749")
        try item.moveTo(Consent.ConsentFormNoticeStatus.cancelled)
        #expect(item.status == Consent.ConsentFormNoticeStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newConsentFormNotice("code-914", name: "name-749")
        item.status = Consent.ConsentFormNoticeStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormNoticeStatus.planned) }
    }
}
