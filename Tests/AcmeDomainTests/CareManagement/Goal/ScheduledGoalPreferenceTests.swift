@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledGoalPreferenceTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newScheduledGoalPreference("code-17", name: "name-227")
        #expect(item.status == CareManagement.ScheduledGoalPreferenceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = CareManagement.newScheduledGoalPreference("code-17", name: "name-227")
        try item.moveTo(CareManagement.ScheduledGoalPreferenceStatus.closed)
        #expect(item.status == CareManagement.ScheduledGoalPreferenceStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newScheduledGoalPreference("code-17", name: "name-227")
        item.status = CareManagement.ScheduledGoalPreferenceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledGoalPreferenceStatus.draft) }
    }
}
