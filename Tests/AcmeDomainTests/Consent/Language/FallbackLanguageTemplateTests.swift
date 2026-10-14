@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackLanguageTemplateTests {
    @Test func startsInOpen() throws {
        let item = Consent.newFallbackLanguageTemplate("code-866", title: "title-38")
        #expect(item.status == Consent.FallbackLanguageTemplateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newFallbackLanguageTemplate("code-866", title: "title-38")
        try item.moveTo(Consent.FallbackLanguageTemplateStatus.resolved)
        #expect(item.status == Consent.FallbackLanguageTemplateStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newFallbackLanguageTemplate("code-866", title: "title-38")
        item.status = Consent.FallbackLanguageTemplateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.FallbackLanguageTemplateStatus.`open`) }
    }
}
