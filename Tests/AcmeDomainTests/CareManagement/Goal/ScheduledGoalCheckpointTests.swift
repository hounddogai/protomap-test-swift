@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledGoalCheckpointTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newScheduledGoalCheckpoint("code-284", title: "title-359")
        #expect(item.status == CareManagement.ScheduledGoalCheckpointStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newScheduledGoalCheckpoint("code-284", title: "title-359")
        try item.moveTo(CareManagement.ScheduledGoalCheckpointStatus.running)
        #expect(item.status == CareManagement.ScheduledGoalCheckpointStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newScheduledGoalCheckpoint("code-284", title: "title-359")
        item.status = CareManagement.ScheduledGoalCheckpointStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledGoalCheckpointStatus.new) }
    }
}
