@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingGoalScheduleTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newPendingGoalSchedule("code-822", name: "name-976")
        #expect(item.status == CareManagement.PendingGoalScheduleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newPendingGoalSchedule("code-822", name: "name-976")
        try item.moveTo(CareManagement.PendingGoalScheduleStatus.rejected)
        #expect(item.status == CareManagement.PendingGoalScheduleStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newPendingGoalSchedule("code-822", name: "name-976")
        item.status = CareManagement.PendingGoalScheduleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingGoalScheduleStatus.proposed) }
    }
}
