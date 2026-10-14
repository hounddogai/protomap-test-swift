@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedResultCheckpointTests {
    @Test func startsInRequested() throws {
        let item = Labs.newBatchedResultCheckpoint("code-178", title: "title-649")
        #expect(item.status == Labs.BatchedResultCheckpointStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newBatchedResultCheckpoint("code-178", title: "title-649")
        try item.moveTo(Labs.BatchedResultCheckpointStatus.granted)
        #expect(item.status == Labs.BatchedResultCheckpointStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newBatchedResultCheckpoint("code-178", title: "title-649")
        item.status = Labs.BatchedResultCheckpointStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.BatchedResultCheckpointStatus.requested) }
    }
}
