@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalGoalAssignmentTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newGlobalGoalAssignment("code-829", label: "label-70")
        #expect(item.status == CareManagement.GlobalGoalAssignmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = CareManagement.newGlobalGoalAssignment("code-829", label: "label-70")
        try item.moveTo(CareManagement.GlobalGoalAssignmentStatus.withdrawn)
        #expect(item.status == CareManagement.GlobalGoalAssignmentStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newGlobalGoalAssignment("code-829", label: "label-70")
        item.status = CareManagement.GlobalGoalAssignmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalGoalAssignmentStatus.proposed) }
    }
}
