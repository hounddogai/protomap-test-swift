@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalAcuityPlanBudgetTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newSeasonalAcuityPlanBudget("code-538", name: "name-531")
        #expect(item.status == Staffing.SeasonalAcuityPlanBudgetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newSeasonalAcuityPlanBudget("code-538", name: "name-531")
        try item.moveTo(Staffing.SeasonalAcuityPlanBudgetStatus.resolved)
        #expect(item.status == Staffing.SeasonalAcuityPlanBudgetStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newSeasonalAcuityPlanBudget("code-538", name: "name-531")
        item.status = Staffing.SeasonalAcuityPlanBudgetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SeasonalAcuityPlanBudgetStatus.`open`) }
    }
}
