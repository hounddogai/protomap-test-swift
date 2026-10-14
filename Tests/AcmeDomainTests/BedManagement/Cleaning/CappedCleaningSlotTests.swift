@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedCleaningSlotTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newCappedCleaningSlot("code-201", label: "label-812")
        #expect(item.status == BedManagement.CappedCleaningSlotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newCappedCleaningSlot("code-201", label: "label-812")
        try item.moveTo(BedManagement.CappedCleaningSlotStatus.approved)
        #expect(item.status == BedManagement.CappedCleaningSlotStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newCappedCleaningSlot("code-201", label: "label-812")
        item.status = BedManagement.CappedCleaningSlotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedCleaningSlotStatus.proposed) }
    }
}
