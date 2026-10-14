@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledProxyDraftTests {
    @Test func startsInNew() throws {
        let item = Consent.newScheduledProxyDraft("code-855", name: "name-202")
        #expect(item.status == Consent.ScheduledProxyDraftStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Consent.newScheduledProxyDraft("code-855", name: "name-202")
        try item.moveTo(Consent.ScheduledProxyDraftStatus.failed)
        #expect(item.status == Consent.ScheduledProxyDraftStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newScheduledProxyDraft("code-855", name: "name-202")
        item.status = Consent.ScheduledProxyDraftStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledProxyDraftStatus.new) }
    }
}
