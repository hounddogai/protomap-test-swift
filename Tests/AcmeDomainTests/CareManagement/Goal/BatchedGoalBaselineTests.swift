@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedGoalBaselineTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newBatchedGoalBaseline("code-237", title: "title-303")
        #expect(item.status == CareManagement.BatchedGoalBaselineStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newBatchedGoalBaseline("code-237", title: "title-303")
        try item.moveTo(CareManagement.BatchedGoalBaselineStatus.pending)
        #expect(item.status == CareManagement.BatchedGoalBaselineStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newBatchedGoalBaseline("code-237", title: "title-303")
        item.status = CareManagement.BatchedGoalBaselineStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedGoalBaselineStatus.draft) }
    }
}
