@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingGoalPreferenceTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newPendingGoalPreference("code-936", name: "name-108")
        #expect(item.status == CareManagement.PendingGoalPreferenceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newPendingGoalPreference("code-936", name: "name-108")
        try item.moveTo(CareManagement.PendingGoalPreferenceStatus.approved)
        #expect(item.status == CareManagement.PendingGoalPreferenceStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newPendingGoalPreference("code-936", name: "name-108")
        item.status = CareManagement.PendingGoalPreferenceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingGoalPreferenceStatus.proposed) }
    }
}
