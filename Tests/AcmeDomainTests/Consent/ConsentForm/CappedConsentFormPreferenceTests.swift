@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedConsentFormPreferenceTests {
    @Test func startsInCreated() throws {
        let item = Consent.newCappedConsentFormPreference("code-993", name: "name-26")
        #expect(item.status == Consent.CappedConsentFormPreferenceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Consent.newCappedConsentFormPreference("code-993", name: "name-26")
        try item.moveTo(Consent.CappedConsentFormPreferenceStatus.retired)
        #expect(item.status == Consent.CappedConsentFormPreferenceStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newCappedConsentFormPreference("code-993", name: "name-26")
        item.status = Consent.CappedConsentFormPreferenceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedConsentFormPreferenceStatus.created) }
    }
}
