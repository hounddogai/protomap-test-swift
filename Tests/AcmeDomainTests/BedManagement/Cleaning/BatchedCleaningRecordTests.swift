@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCleaningRecordTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newBatchedCleaningRecord("code-535", label: "label-737")
        #expect(item.status == BedManagement.BatchedCleaningRecordStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newBatchedCleaningRecord("code-535", label: "label-737")
        try item.moveTo(BedManagement.BatchedCleaningRecordStatus.scheduled)
        #expect(item.status == BedManagement.BatchedCleaningRecordStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newBatchedCleaningRecord("code-535", label: "label-737")
        item.status = BedManagement.BatchedCleaningRecordStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BatchedCleaningRecordStatus.planned) }
    }
}
