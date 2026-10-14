@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingGoalBatchTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newRollingGoalBatch("code-350", name: "name-768")
        #expect(item.status == CareManagement.RollingGoalBatchStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = CareManagement.newRollingGoalBatch("code-350", name: "name-768")
        try item.moveTo(CareManagement.RollingGoalBatchStatus.suspended)
        #expect(item.status == CareManagement.RollingGoalBatchStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newRollingGoalBatch("code-350", name: "name-768")
        item.status = CareManagement.RollingGoalBatchStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RollingGoalBatchStatus.draft) }
    }
}
