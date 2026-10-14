@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormAllocationTests {
    @Test func startsInDraft() throws {
        let item = Consent.newRollingConsentFormAllocation("code-558", label: "label-341")
        #expect(item.status == Consent.RollingConsentFormAllocationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newRollingConsentFormAllocation("code-558", label: "label-341")
        try item.moveTo(Consent.RollingConsentFormAllocationStatus.pending)
        #expect(item.status == Consent.RollingConsentFormAllocationStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newRollingConsentFormAllocation("code-558", label: "label-341")
        item.status = Consent.RollingConsentFormAllocationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingConsentFormAllocationStatus.draft) }
    }
}
