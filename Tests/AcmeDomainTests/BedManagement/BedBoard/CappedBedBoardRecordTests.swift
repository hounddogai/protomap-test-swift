@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedBedBoardRecordTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newCappedBedBoardRecord("code-980", title: "title-105")
        #expect(item.status == BedManagement.CappedBedBoardRecordStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newCappedBedBoardRecord("code-980", title: "title-105")
        try item.moveTo(BedManagement.CappedBedBoardRecordStatus.pending)
        #expect(item.status == BedManagement.CappedBedBoardRecordStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newCappedBedBoardRecord("code-980", title: "title-105")
        item.status = BedManagement.CappedBedBoardRecordStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedBedBoardRecordStatus.draft) }
    }
}
