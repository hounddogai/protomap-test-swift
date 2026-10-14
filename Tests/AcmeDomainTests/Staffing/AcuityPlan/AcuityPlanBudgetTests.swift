@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanBudgetTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newAcuityPlanBudget("code-101", name: "name-612")
        #expect(item.status == Staffing.AcuityPlanBudgetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newAcuityPlanBudget("code-101", name: "name-612")
        try item.moveTo(Staffing.AcuityPlanBudgetStatus.pending)
        #expect(item.status == Staffing.AcuityPlanBudgetStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newAcuityPlanBudget("code-101", name: "name-612")
        item.status = Staffing.AcuityPlanBudgetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanBudgetStatus.draft) }
    }
}
