@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedLanguageBundleTests {
    @Test func startsInRequested() throws {
        let item = Consent.newCappedLanguageBundle("code-213", label: "label-389")
        #expect(item.status == Consent.CappedLanguageBundleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newCappedLanguageBundle("code-213", label: "label-389")
        try item.moveTo(Consent.CappedLanguageBundleStatus.granted)
        #expect(item.status == Consent.CappedLanguageBundleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newCappedLanguageBundle("code-213", label: "label-389")
        item.status = Consent.CappedLanguageBundleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedLanguageBundleStatus.requested) }
    }
}
