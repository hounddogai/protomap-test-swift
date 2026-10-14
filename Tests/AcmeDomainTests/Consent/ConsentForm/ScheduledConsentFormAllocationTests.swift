@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledConsentFormAllocationTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newScheduledConsentFormAllocation("code-945", label: "label-165")
        #expect(item.status == Consent.ScheduledConsentFormAllocationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newScheduledConsentFormAllocation("code-945", label: "label-165")
        try item.moveTo(Consent.ScheduledConsentFormAllocationStatus.scheduled)
        #expect(item.status == Consent.ScheduledConsentFormAllocationStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newScheduledConsentFormAllocation("code-945", label: "label-165")
        item.status = Consent.ScheduledConsentFormAllocationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ScheduledConsentFormAllocationStatus.planned) }
    }
}
