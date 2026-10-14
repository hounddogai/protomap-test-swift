@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledShiftGroupTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newScheduledShiftGroup("code-449", label: "label-839")
        #expect(item.status == Staffing.ScheduledShiftGroupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Staffing.newScheduledShiftGroup("code-449", label: "label-839")
        try item.moveTo(Staffing.ScheduledShiftGroupStatus.suspended)
        #expect(item.status == Staffing.ScheduledShiftGroupStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newScheduledShiftGroup("code-449", label: "label-839")
        item.status = Staffing.ScheduledShiftGroupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ScheduledShiftGroupStatus.draft) }
    }
}
