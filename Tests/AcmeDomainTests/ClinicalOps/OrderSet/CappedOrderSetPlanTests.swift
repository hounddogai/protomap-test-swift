@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedOrderSetPlanTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newCappedOrderSetPlan("code-451", label: "label-385")
        #expect(item.status == ClinicalOps.CappedOrderSetPlanStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = ClinicalOps.newCappedOrderSetPlan("code-451", label: "label-385")
        try item.moveTo(ClinicalOps.CappedOrderSetPlanStatus.failed)
        #expect(item.status == ClinicalOps.CappedOrderSetPlanStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newCappedOrderSetPlan("code-451", label: "label-385")
        item.status = ClinicalOps.CappedOrderSetPlanStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CappedOrderSetPlanStatus.new) }
    }
}
