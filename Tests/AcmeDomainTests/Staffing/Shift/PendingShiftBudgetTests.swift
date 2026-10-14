@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingShiftBudgetTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newPendingShiftBudget("code-297", title: "title-981")
        #expect(item.status == Staffing.PendingShiftBudgetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Staffing.newPendingShiftBudget("code-297", title: "title-981")
        try item.moveTo(Staffing.PendingShiftBudgetStatus.inProgress)
        #expect(item.status == Staffing.PendingShiftBudgetStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newPendingShiftBudget("code-297", title: "title-981")
        item.status = Staffing.PendingShiftBudgetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PendingShiftBudgetStatus.planned) }
    }
}
