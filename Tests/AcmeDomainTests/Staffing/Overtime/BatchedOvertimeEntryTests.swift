@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimeEntryTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newBatchedOvertimeEntry("code-272", title: "title-482")
        #expect(item.status == Staffing.BatchedOvertimeEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newBatchedOvertimeEntry("code-272", title: "title-482")
        try item.moveTo(Staffing.BatchedOvertimeEntryStatus.active)
        #expect(item.status == Staffing.BatchedOvertimeEntryStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newBatchedOvertimeEntry("code-272", title: "title-482")
        item.status = Staffing.BatchedOvertimeEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.BatchedOvertimeEntryStatus.draft) }
    }
}
