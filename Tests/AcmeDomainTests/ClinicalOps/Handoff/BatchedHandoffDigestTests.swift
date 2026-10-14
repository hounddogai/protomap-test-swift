@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedHandoffDigestTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newBatchedHandoffDigest("code-299", title: "title-51")
        #expect(item.status == ClinicalOps.BatchedHandoffDigestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = ClinicalOps.newBatchedHandoffDigest("code-299", title: "title-51")
        try item.moveTo(ClinicalOps.BatchedHandoffDigestStatus.ready)
        #expect(item.status == ClinicalOps.BatchedHandoffDigestStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newBatchedHandoffDigest("code-299", title: "title-51")
        item.status = ClinicalOps.BatchedHandoffDigestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.BatchedHandoffDigestStatus.idle) }
    }
}
