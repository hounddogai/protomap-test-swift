@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryAlertMetricTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newPrimaryAlertMetric("code-60", title: "title-982")
        #expect(item.status == ClinicalOps.PrimaryAlertMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newPrimaryAlertMetric("code-60", title: "title-982")
        try item.moveTo(ClinicalOps.PrimaryAlertMetricStatus.withdrawn)
        #expect(item.status == ClinicalOps.PrimaryAlertMetricStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newPrimaryAlertMetric("code-60", title: "title-982")
        item.status = ClinicalOps.PrimaryAlertMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryAlertMetricStatus.proposed) }
    }
}
