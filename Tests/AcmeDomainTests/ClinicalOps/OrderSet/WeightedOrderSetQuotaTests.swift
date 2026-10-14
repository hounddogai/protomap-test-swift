@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedOrderSetQuotaTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newWeightedOrderSetQuota("code-612", label: "label-346")
        #expect(item.status == ClinicalOps.WeightedOrderSetQuotaStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newWeightedOrderSetQuota("code-612", label: "label-346")
        try item.moveTo(ClinicalOps.WeightedOrderSetQuotaStatus.queued)
        #expect(item.status == ClinicalOps.WeightedOrderSetQuotaStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newWeightedOrderSetQuota("code-612", label: "label-346")
        item.status = ClinicalOps.WeightedOrderSetQuotaStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.WeightedOrderSetQuotaStatus.new) }
    }
}
