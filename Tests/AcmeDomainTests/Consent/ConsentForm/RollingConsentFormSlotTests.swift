@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormSlotTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newRollingConsentFormSlot("code-716", label: "label-581")
        #expect(item.status == Consent.RollingConsentFormSlotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newRollingConsentFormSlot("code-716", label: "label-581")
        try item.moveTo(Consent.RollingConsentFormSlotStatus.scheduled)
        #expect(item.status == Consent.RollingConsentFormSlotStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newRollingConsentFormSlot("code-716", label: "label-581")
        item.status = Consent.RollingConsentFormSlotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingConsentFormSlotStatus.planned) }
    }
}
