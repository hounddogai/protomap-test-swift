@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalAllocationTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newGoalAllocation("code-674", label: "label-360")
        #expect(item.status == CareManagement.GoalAllocationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newGoalAllocation("code-674", label: "label-360")
        try item.moveTo(CareManagement.GoalAllocationStatus.reopened)
        #expect(item.status == CareManagement.GoalAllocationStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newGoalAllocation("code-674", label: "label-360")
        item.status = CareManagement.GoalAllocationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalAllocationStatus.`open`) }
    }
}
