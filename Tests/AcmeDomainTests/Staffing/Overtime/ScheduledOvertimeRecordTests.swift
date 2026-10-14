@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledOvertimeRecordTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newScheduledOvertimeRecord("code-971", label: "label-899")
        #expect(item.status == Staffing.ScheduledOvertimeRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Staffing.newScheduledOvertimeRecord("code-971", label: "label-899")
        try item.moveTo(Staffing.ScheduledOvertimeRecordStatus.withdrawn)
        #expect(item.status == Staffing.ScheduledOvertimeRecordStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newScheduledOvertimeRecord("code-971", label: "label-899")
        item.status = Staffing.ScheduledOvertimeRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ScheduledOvertimeRecordStatus.proposed) }
    }
}
