@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardSlotTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newBedBoardSlot("code-145", name: "name-426")
        #expect(item.status == BedManagement.BedBoardSlotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newBedBoardSlot("code-145", name: "name-426")
        try item.moveTo(BedManagement.BedBoardSlotStatus.granted)
        #expect(item.status == BedManagement.BedBoardSlotStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newBedBoardSlot("code-145", name: "name-426")
        item.status = BedManagement.BedBoardSlotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardSlotStatus.requested) }
    }
}
