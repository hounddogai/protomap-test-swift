@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftBudgetTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newShiftBudget("code-503", title: "title-676")
        #expect(item.status == Staffing.ShiftBudgetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newShiftBudget("code-503", title: "title-676")
        try item.moveTo(Staffing.ShiftBudgetStatus.granted)
        #expect(item.status == Staffing.ShiftBudgetStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newShiftBudget("code-503", title: "title-676")
        item.status = Staffing.ShiftBudgetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftBudgetStatus.requested) }
    }
}
