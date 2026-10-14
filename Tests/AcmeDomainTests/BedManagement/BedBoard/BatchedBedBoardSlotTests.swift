@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedBedBoardSlotTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newBatchedBedBoardSlot("code-329", title: "title-713")
        #expect(item.status == BedManagement.BatchedBedBoardSlotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newBatchedBedBoardSlot("code-329", title: "title-713")
        try item.moveTo(BedManagement.BatchedBedBoardSlotStatus.granted)
        #expect(item.status == BedManagement.BatchedBedBoardSlotStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newBatchedBedBoardSlot("code-329", title: "title-713")
        item.status = BedManagement.BatchedBedBoardSlotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BatchedBedBoardSlotStatus.requested) }
    }
}
