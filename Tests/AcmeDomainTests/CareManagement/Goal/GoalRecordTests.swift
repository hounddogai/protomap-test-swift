@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalRecordTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newGoalRecord("code-7", title: "title-128")
        #expect(item.status == CareManagement.GoalRecordStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = CareManagement.newGoalRecord("code-7", title: "title-128")
        try item.moveTo(CareManagement.GoalRecordStatus.inProgress)
        #expect(item.status == CareManagement.GoalRecordStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newGoalRecord("code-7", title: "title-128")
        item.status = CareManagement.GoalRecordStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalRecordStatus.planned) }
    }
}
