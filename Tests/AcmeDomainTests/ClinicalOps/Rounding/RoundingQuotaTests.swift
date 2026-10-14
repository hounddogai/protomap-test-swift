@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingQuotaTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newRoundingQuota("code-300", title: "title-236")
        #expect(item.status == ClinicalOps.RoundingQuotaStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = ClinicalOps.newRoundingQuota("code-300", title: "title-236")
        try item.moveTo(ClinicalOps.RoundingQuotaStatus.ready)
        #expect(item.status == ClinicalOps.RoundingQuotaStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newRoundingQuota("code-300", title: "title-236")
        item.status = ClinicalOps.RoundingQuotaStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingQuotaStatus.idle) }
    }
}
