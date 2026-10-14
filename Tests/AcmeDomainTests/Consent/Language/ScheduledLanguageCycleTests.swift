@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledLanguageCycleTests {
    @Test func startsInDraft() throws {
        let item = Consent.newScheduledLanguageCycle("code-604", title: "title-976")
        #expect(item.status == Consent.ScheduledLanguageCycleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newScheduledLanguageCycle("code-604", title: "title-976")
        try item.moveTo(Consent.ScheduledLanguageCycleStatus.pending)
        #expect(item.status == Consent.ScheduledLanguageCycleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newScheduledLanguageCycle("code-604", title: "title-976")
        item.status = Consent.ScheduledLanguageCycleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledLanguageCycleStatus.draft) }
    }
}
