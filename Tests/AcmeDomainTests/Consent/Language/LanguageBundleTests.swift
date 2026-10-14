@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageBundleTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newLanguageBundle("code-34", name: "name-704")
        #expect(item.status == Consent.LanguageBundleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newLanguageBundle("code-34", name: "name-704")
        try item.moveTo(Consent.LanguageBundleStatus.scheduled)
        #expect(item.status == Consent.LanguageBundleStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newLanguageBundle("code-34", name: "name-704")
        item.status = Consent.LanguageBundleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageBundleStatus.planned) }
    }
}
