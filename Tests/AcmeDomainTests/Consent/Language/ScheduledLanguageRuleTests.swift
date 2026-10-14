@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledLanguageRuleTests {
    @Test func startsInOpen() throws {
        let item = Consent.newScheduledLanguageRule("code-894", label: "label-83")
        #expect(item.status == Consent.ScheduledLanguageRuleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newScheduledLanguageRule("code-894", label: "label-83")
        try item.moveTo(Consent.ScheduledLanguageRuleStatus.resolved)
        #expect(item.status == Consent.ScheduledLanguageRuleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newScheduledLanguageRule("code-894", label: "label-83")
        item.status = Consent.ScheduledLanguageRuleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledLanguageRuleStatus.`open`) }
    }
}
