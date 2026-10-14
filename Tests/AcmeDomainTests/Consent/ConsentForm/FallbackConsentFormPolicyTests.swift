@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackConsentFormPolicyTests {
    @Test func startsInProposed() throws {
        let item = Consent.newFallbackConsentFormPolicy("code-715", label: "label-887")
        #expect(item.status == Consent.FallbackConsentFormPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newFallbackConsentFormPolicy("code-715", label: "label-887")
        try item.moveTo(Consent.FallbackConsentFormPolicyStatus.rejected)
        #expect(item.status == Consent.FallbackConsentFormPolicyStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newFallbackConsentFormPolicy("code-715", label: "label-887")
        item.status = Consent.FallbackConsentFormPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.FallbackConsentFormPolicyStatus.proposed) }
    }
}
