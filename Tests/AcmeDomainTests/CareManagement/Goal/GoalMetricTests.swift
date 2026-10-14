@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalMetricTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newGoalMetric("code-341", name: "name-140")
        #expect(item.status == CareManagement.GoalMetricStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newGoalMetric("code-341", name: "name-140")
        try item.moveTo(CareManagement.GoalMetricStatus.queued)
        #expect(item.status == CareManagement.GoalMetricStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newGoalMetric("code-341", name: "name-140")
        item.status = CareManagement.GoalMetricStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalMetricStatus.new) }
    }
}
