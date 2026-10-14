@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultOrderSetBatchTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newDefaultOrderSetBatch("code-416", label: "label-831")
        #expect(item.status == ClinicalOps.DefaultOrderSetBatchStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newDefaultOrderSetBatch("code-416", label: "label-831")
        try item.moveTo(ClinicalOps.DefaultOrderSetBatchStatus.revoked)
        #expect(item.status == ClinicalOps.DefaultOrderSetBatchStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newDefaultOrderSetBatch("code-416", label: "label-831")
        item.status = ClinicalOps.DefaultOrderSetBatchStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultOrderSetBatchStatus.requested) }
    }
}
