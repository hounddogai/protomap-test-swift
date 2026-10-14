@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalAssignmentTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newGoalAssignment("code-455", title: "title-100")
        #expect(item.status == CareManagement.GoalAssignmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newGoalAssignment("code-455", title: "title-100")
        try item.moveTo(CareManagement.GoalAssignmentStatus.pending)
        #expect(item.status == CareManagement.GoalAssignmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newGoalAssignment("code-455", title: "title-100")
        item.status = CareManagement.GoalAssignmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalAssignmentStatus.draft) }
    }
}
