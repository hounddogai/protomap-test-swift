@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveConsentFormAllocationTests {
    @Test func startsInRequested() throws {
        let item = Consent.newAdaptiveConsentFormAllocation("code-854", name: "name-487")
        #expect(item.status == Consent.AdaptiveConsentFormAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newAdaptiveConsentFormAllocation("code-854", name: "name-487")
        try item.moveTo(Consent.AdaptiveConsentFormAllocationStatus.granted)
        #expect(item.status == Consent.AdaptiveConsentFormAllocationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newAdaptiveConsentFormAllocation("code-854", name: "name-487")
        item.status = Consent.AdaptiveConsentFormAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveConsentFormAllocationStatus.requested) }
    }
}
