@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardSnapshotTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newBedBoardSnapshot("code-590", name: "name-92")
        #expect(item.status == BedManagement.BedBoardSnapshotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newBedBoardSnapshot("code-590", name: "name-92")
        try item.moveTo(BedManagement.BedBoardSnapshotStatus.inProgress)
        #expect(item.status == BedManagement.BedBoardSnapshotStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newBedBoardSnapshot("code-590", name: "name-92")
        item.status = BedManagement.BedBoardSnapshotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardSnapshotStatus.planned) }
    }
}
