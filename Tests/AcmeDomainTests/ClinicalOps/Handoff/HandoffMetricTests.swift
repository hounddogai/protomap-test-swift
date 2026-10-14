@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffMetricTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newHandoffMetric("code-334", label: "label-400")
        #expect(item.status == ClinicalOps.HandoffMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newHandoffMetric("code-334", label: "label-400")
        try item.moveTo(ClinicalOps.HandoffMetricStatus.withdrawn)
        #expect(item.status == ClinicalOps.HandoffMetricStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newHandoffMetric("code-334", label: "label-400")
        item.status = ClinicalOps.HandoffMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffMetricStatus.proposed) }
    }
}
