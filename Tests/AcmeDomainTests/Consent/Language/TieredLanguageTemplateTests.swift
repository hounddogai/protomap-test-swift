@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredLanguageTemplateTests {
    @Test func startsInRequested() throws {
        let item = Consent.newTieredLanguageTemplate("code-516", title: "title-260")
        #expect(item.status == Consent.TieredLanguageTemplateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newTieredLanguageTemplate("code-516", title: "title-260")
        try item.moveTo(Consent.TieredLanguageTemplateStatus.granted)
        #expect(item.status == Consent.TieredLanguageTemplateStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newTieredLanguageTemplate("code-516", title: "title-260")
        item.status = Consent.TieredLanguageTemplateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.TieredLanguageTemplateStatus.requested) }
    }
}
