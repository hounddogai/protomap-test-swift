@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormPreferenceTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newConsentFormPreference("code-619", name: "name-216")
        #expect(item.status == Consent.ConsentFormPreferenceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Consent.newConsentFormPreference("code-619", name: "name-216")
        try item.moveTo(Consent.ConsentFormPreferenceStatus.completed)
        #expect(item.status == Consent.ConsentFormPreferenceStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newConsentFormPreference("code-619", name: "name-216")
        item.status = Consent.ConsentFormPreferenceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormPreferenceStatus.planned) }
    }
}
