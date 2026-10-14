@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualAlertMetricTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newManualAlertMetric("code-174", label: "label-920")
        #expect(item.status == ClinicalOps.ManualAlertMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newManualAlertMetric("code-174", label: "label-920")
        try item.moveTo(ClinicalOps.ManualAlertMetricStatus.approved)
        #expect(item.status == ClinicalOps.ManualAlertMetricStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newManualAlertMetric("code-174", label: "label-920")
        item.status = ClinicalOps.ManualAlertMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ManualAlertMetricStatus.proposed) }
    }
}
