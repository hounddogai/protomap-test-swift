@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalCycleTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newGoalCycle("code-843", name: "name-87")
        #expect(item.status == CareManagement.GoalCycleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newGoalCycle("code-843", name: "name-87")
        try item.moveTo(CareManagement.GoalCycleStatus.warming)
        #expect(item.status == CareManagement.GoalCycleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newGoalCycle("code-843", name: "name-87")
        item.status = CareManagement.GoalCycleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalCycleStatus.idle) }
    }
}
