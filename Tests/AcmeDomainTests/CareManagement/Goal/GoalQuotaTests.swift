@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalQuotaTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newGoalQuota("code-909", label: "label-584")
        #expect(item.status == CareManagement.GoalQuotaStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newGoalQuota("code-909", label: "label-584")
        try item.moveTo(CareManagement.GoalQuotaStatus.queued)
        #expect(item.status == CareManagement.GoalQuotaStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newGoalQuota("code-909", label: "label-584")
        item.status = CareManagement.GoalQuotaStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalQuotaStatus.new) }
    }
}
