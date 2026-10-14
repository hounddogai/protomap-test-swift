@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftBaselineTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newShiftBaseline("code-281", title: "title-101")
        #expect(item.status == Staffing.ShiftBaselineStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Staffing.newShiftBaseline("code-281", title: "title-101")
        try item.moveTo(Staffing.ShiftBaselineStatus.completed)
        #expect(item.status == Staffing.ShiftBaselineStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newShiftBaseline("code-281", title: "title-101")
        item.status = Staffing.ShiftBaselineStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftBaselineStatus.planned) }
    }
}
