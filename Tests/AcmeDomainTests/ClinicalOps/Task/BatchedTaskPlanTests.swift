@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedTaskPlanTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newBatchedTaskPlan("code-562", label: "label-243")
        #expect(item.status == ClinicalOps.BatchedTaskPlanStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = ClinicalOps.newBatchedTaskPlan("code-562", label: "label-243")
        try item.moveTo(ClinicalOps.BatchedTaskPlanStatus.ready)
        #expect(item.status == ClinicalOps.BatchedTaskPlanStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newBatchedTaskPlan("code-562", label: "label-243")
        item.status = ClinicalOps.BatchedTaskPlanStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.BatchedTaskPlanStatus.idle) }
    }
}
