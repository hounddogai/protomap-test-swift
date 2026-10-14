@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedConsentFormRuleTests {
    @Test func startsInRequested() throws {
        let item = Consent.newCappedConsentFormRule("code-799", name: "name-259")
        #expect(item.status == Consent.CappedConsentFormRuleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newCappedConsentFormRule("code-799", name: "name-259")
        try item.moveTo(Consent.CappedConsentFormRuleStatus.granted)
        #expect(item.status == Consent.CappedConsentFormRuleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newCappedConsentFormRule("code-799", name: "name-259")
        item.status = Consent.CappedConsentFormRuleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedConsentFormRuleStatus.requested) }
    }
}
