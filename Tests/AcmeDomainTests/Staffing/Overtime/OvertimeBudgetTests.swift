@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeBudgetTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newOvertimeBudget("code-595", name: "name-692")
        #expect(item.status == Staffing.OvertimeBudgetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Staffing.newOvertimeBudget("code-595", name: "name-692")
        try item.moveTo(Staffing.OvertimeBudgetStatus.suspended)
        #expect(item.status == Staffing.OvertimeBudgetStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newOvertimeBudget("code-595", name: "name-692")
        item.status = Staffing.OvertimeBudgetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeBudgetStatus.draft) }
    }
}
