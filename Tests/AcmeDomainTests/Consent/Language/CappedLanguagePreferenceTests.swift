@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedLanguagePreferenceTests {
    @Test func startsInOpen() throws {
        let item = Consent.newCappedLanguagePreference("code-346", label: "label-864")
        #expect(item.status == Consent.CappedLanguagePreferenceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newCappedLanguagePreference("code-346", label: "label-864")
        try item.moveTo(Consent.CappedLanguagePreferenceStatus.resolved)
        #expect(item.status == Consent.CappedLanguagePreferenceStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newCappedLanguagePreference("code-346", label: "label-864")
        item.status = Consent.CappedLanguagePreferenceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedLanguagePreferenceStatus.`open`) }
    }
}
