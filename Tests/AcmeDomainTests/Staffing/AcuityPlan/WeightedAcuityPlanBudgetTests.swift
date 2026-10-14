@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedAcuityPlanBudgetTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newWeightedAcuityPlanBudget("code-490", label: "label-276")
        #expect(item.status == Staffing.WeightedAcuityPlanBudgetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newWeightedAcuityPlanBudget("code-490", label: "label-276")
        try item.moveTo(Staffing.WeightedAcuityPlanBudgetStatus.approved)
        #expect(item.status == Staffing.WeightedAcuityPlanBudgetStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newWeightedAcuityPlanBudget("code-490", label: "label-276")
        item.status = Staffing.WeightedAcuityPlanBudgetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.WeightedAcuityPlanBudgetStatus.proposed) }
    }
}
