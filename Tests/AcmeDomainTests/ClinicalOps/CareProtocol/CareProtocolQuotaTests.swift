@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolQuotaTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newCareProtocolQuota("code-736", label: "label-291")
        #expect(item.status == ClinicalOps.CareProtocolQuotaStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = ClinicalOps.newCareProtocolQuota("code-736", label: "label-291")
        try item.moveTo(ClinicalOps.CareProtocolQuotaStatus.draining)
        #expect(item.status == ClinicalOps.CareProtocolQuotaStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newCareProtocolQuota("code-736", label: "label-291")
        item.status = ClinicalOps.CareProtocolQuotaStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolQuotaStatus.idle) }
    }
}
