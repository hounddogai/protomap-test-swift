@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedCareProtocolQuotaTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newBatchedCareProtocolQuota("code-604", label: "label-790")
        #expect(item.status == ClinicalOps.BatchedCareProtocolQuotaStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newBatchedCareProtocolQuota("code-604", label: "label-790")
        try item.moveTo(ClinicalOps.BatchedCareProtocolQuotaStatus.withdrawn)
        #expect(item.status == ClinicalOps.BatchedCareProtocolQuotaStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newBatchedCareProtocolQuota("code-604", label: "label-790")
        item.status = ClinicalOps.BatchedCareProtocolQuotaStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.BatchedCareProtocolQuotaStatus.proposed) }
    }
}
