@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveLanguageTemplateTests {
    @Test func startsInRequested() throws {
        let item = Consent.newAdaptiveLanguageTemplate("code-528", title: "title-921")
        #expect(item.status == Consent.AdaptiveLanguageTemplateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newAdaptiveLanguageTemplate("code-528", title: "title-921")
        try item.moveTo(Consent.AdaptiveLanguageTemplateStatus.granted)
        #expect(item.status == Consent.AdaptiveLanguageTemplateStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newAdaptiveLanguageTemplate("code-528", title: "title-921")
        item.status = Consent.AdaptiveLanguageTemplateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveLanguageTemplateStatus.requested) }
    }
}
