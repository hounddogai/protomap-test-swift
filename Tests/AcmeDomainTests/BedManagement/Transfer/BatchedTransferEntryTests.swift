@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedTransferEntryTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newBatchedTransferEntry("code-118", name: "name-977")
        #expect(item.status == BedManagement.BatchedTransferEntryStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newBatchedTransferEntry("code-118", name: "name-977")
        try item.moveTo(BedManagement.BatchedTransferEntryStatus.granted)
        #expect(item.status == BedManagement.BatchedTransferEntryStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newBatchedTransferEntry("code-118", name: "name-977")
        item.status = BedManagement.BatchedTransferEntryStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BatchedTransferEntryStatus.requested) }
    }
}
