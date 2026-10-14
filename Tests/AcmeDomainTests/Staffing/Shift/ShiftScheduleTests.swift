@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftScheduleTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newShiftSchedule("code-889", label: "label-320")
        #expect(item.status == Staffing.ShiftScheduleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newShiftSchedule("code-889", label: "label-320")
        try item.moveTo(Staffing.ShiftScheduleStatus.published)
        #expect(item.status == Staffing.ShiftScheduleStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newShiftSchedule("code-889", label: "label-320")
        item.status = Staffing.ShiftScheduleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftScheduleStatus.created) }
    }
}
