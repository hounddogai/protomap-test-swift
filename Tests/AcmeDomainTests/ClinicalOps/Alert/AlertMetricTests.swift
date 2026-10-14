@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertMetricTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newAlertMetric("code-232", label: "label-310")
        #expect(item.status == ClinicalOps.AlertMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newAlertMetric("code-232", label: "label-310")
        try item.moveTo(ClinicalOps.AlertMetricStatus.granted)
        #expect(item.status == ClinicalOps.AlertMetricStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newAlertMetric("code-232", label: "label-310")
        item.status = ClinicalOps.AlertMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertMetricStatus.requested) }
    }
}
