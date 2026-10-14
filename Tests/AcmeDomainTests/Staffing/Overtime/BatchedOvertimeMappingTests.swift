@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimeMappingTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newBatchedOvertimeMapping("code-871", label: "label-54")
        #expect(item.status == Staffing.BatchedOvertimeMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newBatchedOvertimeMapping("code-871", label: "label-54")
        try item.moveTo(Staffing.BatchedOvertimeMappingStatus.scheduled)
        #expect(item.status == Staffing.BatchedOvertimeMappingStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newBatchedOvertimeMapping("code-871", label: "label-54")
        item.status = Staffing.BatchedOvertimeMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.BatchedOvertimeMappingStatus.planned) }
    }
}
