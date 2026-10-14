@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledGoalPolicyTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newScheduledGoalPolicy("code-255", title: "title-533")
        #expect(item.status == CareManagement.ScheduledGoalPolicyStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newScheduledGoalPolicy("code-255", title: "title-533")
        try item.moveTo(CareManagement.ScheduledGoalPolicyStatus.pending)
        #expect(item.status == CareManagement.ScheduledGoalPolicyStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newScheduledGoalPolicy("code-255", title: "title-533")
        item.status = CareManagement.ScheduledGoalPolicyStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledGoalPolicyStatus.draft) }
    }
}
