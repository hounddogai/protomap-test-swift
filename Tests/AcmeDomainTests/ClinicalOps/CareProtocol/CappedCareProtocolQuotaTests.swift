@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedCareProtocolQuotaTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newCappedCareProtocolQuota("code-753", label: "label-426")
        #expect(item.status == ClinicalOps.CappedCareProtocolQuotaStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = ClinicalOps.newCappedCareProtocolQuota("code-753", label: "label-426")
        try item.moveTo(ClinicalOps.CappedCareProtocolQuotaStatus.draining)
        #expect(item.status == ClinicalOps.CappedCareProtocolQuotaStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newCappedCareProtocolQuota("code-753", label: "label-426")
        item.status = ClinicalOps.CappedCareProtocolQuotaStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CappedCareProtocolQuotaStatus.idle) }
    }
}
