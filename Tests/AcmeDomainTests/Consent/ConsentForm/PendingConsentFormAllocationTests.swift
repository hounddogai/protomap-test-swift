@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingConsentFormAllocationTests {
    @Test func startsInRequested() throws {
        let item = Consent.newPendingConsentFormAllocation("code-274", name: "name-626")
        #expect(item.status == Consent.PendingConsentFormAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newPendingConsentFormAllocation("code-274", name: "name-626")
        try item.moveTo(Consent.PendingConsentFormAllocationStatus.granted)
        #expect(item.status == Consent.PendingConsentFormAllocationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newPendingConsentFormAllocation("code-274", name: "name-626")
        item.status = Consent.PendingConsentFormAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PendingConsentFormAllocationStatus.requested) }
    }
}
