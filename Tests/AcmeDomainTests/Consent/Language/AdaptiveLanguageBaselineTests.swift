@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveLanguageBaselineTests {
    @Test func startsInOpen() throws {
        let item = Consent.newAdaptiveLanguageBaseline("code-846", name: "name-675")
        #expect(item.status == Consent.AdaptiveLanguageBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Consent.newAdaptiveLanguageBaseline("code-846", name: "name-675")
        try item.moveTo(Consent.AdaptiveLanguageBaselineStatus.archived)
        #expect(item.status == Consent.AdaptiveLanguageBaselineStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newAdaptiveLanguageBaseline("code-846", name: "name-675")
        item.status = Consent.AdaptiveLanguageBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveLanguageBaselineStatus.`open`) }
    }
}
