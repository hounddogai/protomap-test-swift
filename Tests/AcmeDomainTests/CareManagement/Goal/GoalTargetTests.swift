@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalTargetTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newGoalTarget("code-523", name: "name-851")
        #expect(item.status == CareManagement.GoalTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = CareManagement.newGoalTarget("code-523", name: "name-851")
        try item.moveTo(CareManagement.GoalTargetStatus.archived)
        #expect(item.status == CareManagement.GoalTargetStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newGoalTarget("code-523", name: "name-851")
        item.status = CareManagement.GoalTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalTargetStatus.`open`) }
    }
}
