@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedGoalDraftTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newBatchedGoalDraft("code-121", name: "name-531")
        #expect(item.status == CareManagement.BatchedGoalDraftStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newBatchedGoalDraft("code-121", name: "name-531")
        try item.moveTo(CareManagement.BatchedGoalDraftStatus.reopened)
        #expect(item.status == CareManagement.BatchedGoalDraftStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newBatchedGoalDraft("code-121", name: "name-531")
        item.status = CareManagement.BatchedGoalDraftStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedGoalDraftStatus.`open`) }
    }
}
