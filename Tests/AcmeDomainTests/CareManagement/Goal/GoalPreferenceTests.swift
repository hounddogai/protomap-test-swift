@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalPreferenceTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newGoalPreference("code-711", title: "title-756")
        #expect(item.status == CareManagement.GoalPreferenceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newGoalPreference("code-711", title: "title-756")
        try item.moveTo(CareManagement.GoalPreferenceStatus.published)
        #expect(item.status == CareManagement.GoalPreferenceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newGoalPreference("code-711", title: "title-756")
        item.status = CareManagement.GoalPreferenceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalPreferenceStatus.created) }
    }
}
