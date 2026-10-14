@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledConsentFormDraftTests {
    @Test func startsInOpen() throws {
        let item = Consent.newScheduledConsentFormDraft("code-870", title: "title-793")
        #expect(item.status == Consent.ScheduledConsentFormDraftStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newScheduledConsentFormDraft("code-870", title: "title-793")
        try item.moveTo(Consent.ScheduledConsentFormDraftStatus.resolved)
        #expect(item.status == Consent.ScheduledConsentFormDraftStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newScheduledConsentFormDraft("code-870", title: "title-793")
        item.status = Consent.ScheduledConsentFormDraftStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledConsentFormDraftStatus.`open`) }
    }
}
