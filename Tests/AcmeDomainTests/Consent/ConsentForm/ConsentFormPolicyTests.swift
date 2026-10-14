@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormPolicyTests {
    @Test func startsInNew() throws {
        let item = Consent.newConsentFormPolicy("code-228", name: "name-407")
        #expect(item.status == Consent.ConsentFormPolicyStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newConsentFormPolicy("code-228", name: "name-407")
        try item.moveTo(Consent.ConsentFormPolicyStatus.queued)
        #expect(item.status == Consent.ConsentFormPolicyStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newConsentFormPolicy("code-228", name: "name-407")
        item.status = Consent.ConsentFormPolicyStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ConsentFormPolicyStatus.new) }
    }
}
