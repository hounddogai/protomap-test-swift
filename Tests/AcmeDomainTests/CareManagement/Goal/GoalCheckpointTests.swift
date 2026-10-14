@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalCheckpointTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newGoalCheckpoint("code-262", title: "title-314")
        #expect(item.status == CareManagement.GoalCheckpointStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newGoalCheckpoint("code-262", title: "title-314")
        try item.moveTo(CareManagement.GoalCheckpointStatus.active)
        #expect(item.status == CareManagement.GoalCheckpointStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newGoalCheckpoint("code-262", title: "title-314")
        item.status = CareManagement.GoalCheckpointStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalCheckpointStatus.draft) }
    }
}
