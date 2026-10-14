@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedOrderSetExceptionTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newWeightedOrderSetException("code-699", label: "label-948")
        #expect(item.status == ClinicalOps.WeightedOrderSetExceptionStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newWeightedOrderSetException("code-699", label: "label-948")
        try item.moveTo(ClinicalOps.WeightedOrderSetExceptionStatus.approved)
        #expect(item.status == ClinicalOps.WeightedOrderSetExceptionStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newWeightedOrderSetException("code-699", label: "label-948")
        item.status = ClinicalOps.WeightedOrderSetExceptionStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.WeightedOrderSetExceptionStatus.proposed) }
    }
}
