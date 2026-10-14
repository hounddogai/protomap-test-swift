@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCleaningScheduleTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newBatchedCleaningSchedule("code-936", label: "label-121")
        #expect(item.status == BedManagement.BatchedCleaningScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = BedManagement.newBatchedCleaningSchedule("code-936", label: "label-121")
        try item.moveTo(BedManagement.BatchedCleaningScheduleStatus.completed)
        #expect(item.status == BedManagement.BatchedCleaningScheduleStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newBatchedCleaningSchedule("code-936", label: "label-121")
        item.status = BedManagement.BatchedCleaningScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BatchedCleaningScheduleStatus.planned) }
    }
}
