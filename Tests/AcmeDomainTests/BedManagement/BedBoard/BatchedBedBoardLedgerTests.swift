@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedBedBoardLedgerTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newBatchedBedBoardLedger("code-619", title: "title-794")
        #expect(item.status == BedManagement.BatchedBedBoardLedgerStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newBatchedBedBoardLedger("code-619", title: "title-794")
        try item.moveTo(BedManagement.BatchedBedBoardLedgerStatus.pending)
        #expect(item.status == BedManagement.BatchedBedBoardLedgerStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newBatchedBedBoardLedger("code-619", title: "title-794")
        item.status = BedManagement.BatchedBedBoardLedgerStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BatchedBedBoardLedgerStatus.draft) }
    }
}
