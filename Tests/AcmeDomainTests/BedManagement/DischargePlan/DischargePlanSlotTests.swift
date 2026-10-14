@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanSlotTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newDischargePlanSlot("code-556", name: "name-679")
        #expect(item.status == BedManagement.DischargePlanSlotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newDischargePlanSlot("code-556", name: "name-679")
        try item.moveTo(BedManagement.DischargePlanSlotStatus.granted)
        #expect(item.status == BedManagement.DischargePlanSlotStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newDischargePlanSlot("code-556", name: "name-679")
        item.status = BedManagement.DischargePlanSlotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanSlotStatus.requested) }
    }
}
