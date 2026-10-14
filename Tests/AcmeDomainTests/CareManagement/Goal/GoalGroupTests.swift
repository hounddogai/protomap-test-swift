@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalGroupTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newGoalGroup("code-316", label: "label-304")
        #expect(item.status == CareManagement.GoalGroupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newGoalGroup("code-316", label: "label-304")
        try item.moveTo(CareManagement.GoalGroupStatus.reopened)
        #expect(item.status == CareManagement.GoalGroupStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newGoalGroup("code-316", label: "label-304")
        item.status = CareManagement.GoalGroupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalGroupStatus.`open`) }
    }
}
