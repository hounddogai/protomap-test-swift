@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyCredentialSlotTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newLegacyCredentialSlot("code-990", label: "label-817")
        #expect(item.status == Staffing.LegacyCredentialSlotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newLegacyCredentialSlot("code-990", label: "label-817")
        try item.moveTo(Staffing.LegacyCredentialSlotStatus.granted)
        #expect(item.status == Staffing.LegacyCredentialSlotStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newLegacyCredentialSlot("code-990", label: "label-817")
        item.status = Staffing.LegacyCredentialSlotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LegacyCredentialSlotStatus.requested) }
    }
}
