@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalTemplateTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newGoalTemplate("code-842", title: "title-544")
        #expect(item.status == CareManagement.GoalTemplateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = CareManagement.newGoalTemplate("code-842", title: "title-544")
        try item.moveTo(CareManagement.GoalTemplateStatus.suspended)
        #expect(item.status == CareManagement.GoalTemplateStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newGoalTemplate("code-842", title: "title-544")
        item.status = CareManagement.GoalTemplateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalTemplateStatus.draft) }
    }
}
