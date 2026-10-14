@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedCareProtocolPlanTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newBatchedCareProtocolPlan("code-728", label: "label-890")
        #expect(item.status == ClinicalOps.BatchedCareProtocolPlanStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = ClinicalOps.newBatchedCareProtocolPlan("code-728", label: "label-890")
        try item.moveTo(ClinicalOps.BatchedCareProtocolPlanStatus.completed)
        #expect(item.status == ClinicalOps.BatchedCareProtocolPlanStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newBatchedCareProtocolPlan("code-728", label: "label-890")
        item.status = ClinicalOps.BatchedCareProtocolPlanStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.BatchedCareProtocolPlanStatus.planned) }
    }
}
