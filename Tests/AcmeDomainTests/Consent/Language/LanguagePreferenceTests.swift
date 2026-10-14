@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguagePreferenceTests {
    @Test func startsInRequested() throws {
        let item = Consent.newLanguagePreference("code-546", title: "title-350")
        #expect(item.status == Consent.LanguagePreferenceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newLanguagePreference("code-546", title: "title-350")
        try item.moveTo(Consent.LanguagePreferenceStatus.revoked)
        #expect(item.status == Consent.LanguagePreferenceStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newLanguagePreference("code-546", title: "title-350")
        item.status = Consent.LanguagePreferenceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguagePreferenceStatus.requested) }
    }
}
