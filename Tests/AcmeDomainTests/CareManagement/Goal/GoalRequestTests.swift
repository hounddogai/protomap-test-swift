@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalRequestTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newGoalRequest("code-67", label: "label-504")
        #expect(item.status == CareManagement.GoalRequestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newGoalRequest("code-67", label: "label-504")
        try item.moveTo(CareManagement.GoalRequestStatus.granted)
        #expect(item.status == CareManagement.GoalRequestStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newGoalRequest("code-67", label: "label-504")
        item.status = CareManagement.GoalRequestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalRequestStatus.requested) }
    }
}
