@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedIsolationRecordTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newBatchedIsolationRecord("code-421", label: "label-969")
        #expect(item.status == BedManagement.BatchedIsolationRecordStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newBatchedIsolationRecord("code-421", label: "label-969")
        try item.moveTo(BedManagement.BatchedIsolationRecordStatus.scheduled)
        #expect(item.status == BedManagement.BatchedIsolationRecordStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newBatchedIsolationRecord("code-421", label: "label-969")
        item.status = BedManagement.BatchedIsolationRecordStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BatchedIsolationRecordStatus.planned) }
    }
}
