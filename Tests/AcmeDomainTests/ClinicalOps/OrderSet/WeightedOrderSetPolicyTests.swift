@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedOrderSetPolicyTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newWeightedOrderSetPolicy("code-605", label: "label-209")
        #expect(item.status == ClinicalOps.WeightedOrderSetPolicyStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = ClinicalOps.newWeightedOrderSetPolicy("code-605", label: "label-209")
        try item.moveTo(ClinicalOps.WeightedOrderSetPolicyStatus.failed)
        #expect(item.status == ClinicalOps.WeightedOrderSetPolicyStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newWeightedOrderSetPolicy("code-605", label: "label-209")
        item.status = ClinicalOps.WeightedOrderSetPolicyStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.WeightedOrderSetPolicyStatus.new) }
    }
}
