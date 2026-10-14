@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferSlotTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newTransferSlot("code-711", title: "title-657")
        #expect(item.status == BedManagement.TransferSlotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = BedManagement.newTransferSlot("code-711", title: "title-657")
        try item.moveTo(BedManagement.TransferSlotStatus.suspended)
        #expect(item.status == BedManagement.TransferSlotStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newTransferSlot("code-711", title: "title-657")
        item.status = BedManagement.TransferSlotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferSlotStatus.draft) }
    }
}
