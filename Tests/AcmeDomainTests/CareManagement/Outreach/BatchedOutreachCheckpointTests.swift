@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedOutreachCheckpointTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newBatchedOutreachCheckpoint("code-94", name: "name-501")
        #expect(item.status == CareManagement.BatchedOutreachCheckpointStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newBatchedOutreachCheckpoint("code-94", name: "name-501")
        try item.moveTo(CareManagement.BatchedOutreachCheckpointStatus.queued)
        #expect(item.status == CareManagement.BatchedOutreachCheckpointStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newBatchedOutreachCheckpoint("code-94", name: "name-501")
        item.status = CareManagement.BatchedOutreachCheckpointStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedOutreachCheckpointStatus.new) }
    }
}
