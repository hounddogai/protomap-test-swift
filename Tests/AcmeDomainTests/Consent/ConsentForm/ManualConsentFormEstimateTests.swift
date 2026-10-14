@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualConsentFormEstimateTests {
    @Test func startsInRequested() throws {
        let item = Consent.newManualConsentFormEstimate("code-447", name: "name-731")
        #expect(item.status == Consent.ManualConsentFormEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newManualConsentFormEstimate("code-447", name: "name-731")
        try item.moveTo(Consent.ManualConsentFormEstimateStatus.revoked)
        #expect(item.status == Consent.ManualConsentFormEstimateStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newManualConsentFormEstimate("code-447", name: "name-731")
        item.status = Consent.ManualConsentFormEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ManualConsentFormEstimateStatus.requested) }
    }
}
