@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageRuleTests {
    @Test func startsInRequested() throws {
        let item = Consent.newLanguageRule("code-58", title: "title-340")
        #expect(item.status == Consent.LanguageRuleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newLanguageRule("code-58", title: "title-340")
        try item.moveTo(Consent.LanguageRuleStatus.revoked)
        #expect(item.status == Consent.LanguageRuleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newLanguageRule("code-58", title: "title-340")
        item.status = Consent.LanguageRuleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageRuleStatus.requested) }
    }
}
