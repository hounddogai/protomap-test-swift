@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormRuleTests {
    @Test func startsInCreated() throws {
        let item = Consent.newConsentFormRule("code-170", name: "name-28")
        #expect(item.status == Consent.ConsentFormRuleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newConsentFormRule("code-170", name: "name-28")
        try item.moveTo(Consent.ConsentFormRuleStatus.published)
        #expect(item.status == Consent.ConsentFormRuleStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newConsentFormRule("code-170", name: "name-28")
        item.status = Consent.ConsentFormRuleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormRuleStatus.created) }
    }
}
