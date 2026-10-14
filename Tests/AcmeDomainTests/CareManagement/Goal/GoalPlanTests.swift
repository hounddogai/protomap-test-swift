@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalPlanTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newGoalPlan("code-84", name: "name-761")
        #expect(item.status == CareManagement.GoalPlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newGoalPlan("code-84", name: "name-761")
        try item.moveTo(CareManagement.GoalPlanStatus.approved)
        #expect(item.status == CareManagement.GoalPlanStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newGoalPlan("code-84", name: "name-761")
        item.status = CareManagement.GoalPlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalPlanStatus.proposed) }
    }
}
