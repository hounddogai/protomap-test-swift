@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedCourierBatchTests {
    @Test func startsInIdle() throws {
        let item = Labs.newBatchedCourierBatch("code-250", label: "label-514")
        #expect(item.status == Labs.BatchedCourierBatchStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newBatchedCourierBatch("code-250", label: "label-514")
        try item.moveTo(Labs.BatchedCourierBatchStatus.draining)
        #expect(item.status == Labs.BatchedCourierBatchStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newBatchedCourierBatch("code-250", label: "label-514")
        item.status = Labs.BatchedCourierBatchStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.BatchedCourierBatchStatus.idle) }
    }
}
