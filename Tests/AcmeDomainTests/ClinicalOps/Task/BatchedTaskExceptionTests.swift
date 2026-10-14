@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedTaskExceptionTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newBatchedTaskException("code-814", label: "label-80")
        #expect(item.status == ClinicalOps.BatchedTaskExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = ClinicalOps.newBatchedTaskException("code-814", label: "label-80")
        try item.moveTo(ClinicalOps.BatchedTaskExceptionStatus.ready)
        #expect(item.status == ClinicalOps.BatchedTaskExceptionStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newBatchedTaskException("code-814", label: "label-80")
        item.status = ClinicalOps.BatchedTaskExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.BatchedTaskExceptionStatus.idle) }
    }
}
