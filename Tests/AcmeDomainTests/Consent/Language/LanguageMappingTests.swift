@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageMappingTests {
    @Test func startsInRequested() throws {
        let item = Consent.newLanguageMapping("code-658", label: "label-751")
        #expect(item.status == Consent.LanguageMappingStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newLanguageMapping("code-658", label: "label-751")
        try item.moveTo(Consent.LanguageMappingStatus.granted)
        #expect(item.status == Consent.LanguageMappingStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newLanguageMapping("code-658", label: "label-751")
        item.status = Consent.LanguageMappingStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageMappingStatus.requested) }
    }
}
