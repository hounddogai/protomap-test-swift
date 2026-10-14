@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalBaselineTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newGoalBaseline("code-28", name: "name-857")
        #expect(item.status == CareManagement.GoalBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newGoalBaseline("code-28", name: "name-857")
        try item.moveTo(CareManagement.GoalBaselineStatus.reopened)
        #expect(item.status == CareManagement.GoalBaselineStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newGoalBaseline("code-28", name: "name-857")
        item.status = CareManagement.GoalBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalBaselineStatus.`open`) }
    }
}
