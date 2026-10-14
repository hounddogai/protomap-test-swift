@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultProxyRuleTests {
    @Test func startsInOpen() throws {
        let item = Consent.newDefaultProxyRule("code-109", label: "label-887")
        #expect(item.status == Consent.DefaultProxyRuleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Consent.newDefaultProxyRule("code-109", label: "label-887")
        try item.moveTo(Consent.DefaultProxyRuleStatus.reopened)
        #expect(item.status == Consent.DefaultProxyRuleStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newDefaultProxyRule("code-109", label: "label-887")
        item.status = Consent.DefaultProxyRuleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DefaultProxyRuleStatus.`open`) }
    }
}
