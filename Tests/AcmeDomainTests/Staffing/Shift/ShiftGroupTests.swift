@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftGroupTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newShiftGroup("code-40", title: "title-705")
        #expect(item.status == Staffing.ShiftGroupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newShiftGroup("code-40", title: "title-705")
        try item.moveTo(Staffing.ShiftGroupStatus.scheduled)
        #expect(item.status == Staffing.ShiftGroupStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newShiftGroup("code-40", title: "title-705")
        item.status = Staffing.ShiftGroupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftGroupStatus.planned) }
    }
}
