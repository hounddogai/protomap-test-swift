@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalOverrideTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newGoalOverride("code-906", name: "name-982")
        #expect(item.status == CareManagement.GoalOverrideStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newGoalOverride("code-906", name: "name-982")
        try item.moveTo(CareManagement.GoalOverrideStatus.revoked)
        #expect(item.status == CareManagement.GoalOverrideStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newGoalOverride("code-906", name: "name-982")
        item.status = CareManagement.GoalOverrideStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalOverrideStatus.requested) }
    }
}
