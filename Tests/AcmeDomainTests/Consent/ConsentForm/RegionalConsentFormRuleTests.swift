@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalConsentFormRuleTests {
    @Test func startsInOpen() throws {
        let item = Consent.newRegionalConsentFormRule("code-193", name: "name-428")
        #expect(item.status == Consent.RegionalConsentFormRuleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newRegionalConsentFormRule("code-193", name: "name-428")
        try item.moveTo(Consent.RegionalConsentFormRuleStatus.resolved)
        #expect(item.status == Consent.RegionalConsentFormRuleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newRegionalConsentFormRule("code-193", name: "name-428")
        item.status = Consent.RegionalConsentFormRuleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RegionalConsentFormRuleStatus.`open`) }
    }
}
