@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalScheduleTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newGoalSchedule("code-338", name: "name-298")
        #expect(item.status == CareManagement.GoalScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = CareManagement.newGoalSchedule("code-338", name: "name-298")
        try item.moveTo(CareManagement.GoalScheduleStatus.cancelled)
        #expect(item.status == CareManagement.GoalScheduleStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newGoalSchedule("code-338", name: "name-298")
        item.status = CareManagement.GoalScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalScheduleStatus.planned) }
    }
}
