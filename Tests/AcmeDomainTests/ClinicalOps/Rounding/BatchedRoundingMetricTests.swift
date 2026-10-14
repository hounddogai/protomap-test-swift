@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedRoundingMetricTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newBatchedRoundingMetric("code-385", label: "label-665")
        #expect(item.status == ClinicalOps.BatchedRoundingMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newBatchedRoundingMetric("code-385", label: "label-665")
        try item.moveTo(ClinicalOps.BatchedRoundingMetricStatus.granted)
        #expect(item.status == ClinicalOps.BatchedRoundingMetricStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newBatchedRoundingMetric("code-385", label: "label-665")
        item.status = ClinicalOps.BatchedRoundingMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.BatchedRoundingMetricStatus.requested) }
    }
}
