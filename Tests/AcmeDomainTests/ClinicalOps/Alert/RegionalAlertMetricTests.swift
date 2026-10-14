@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertMetricTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newRegionalAlertMetric("code-731", label: "label-982")
        #expect(item.status == ClinicalOps.RegionalAlertMetricStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newRegionalAlertMetric("code-731", label: "label-982")
        try item.moveTo(ClinicalOps.RegionalAlertMetricStatus.reopened)
        #expect(item.status == ClinicalOps.RegionalAlertMetricStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newRegionalAlertMetric("code-731", label: "label-982")
        item.status = ClinicalOps.RegionalAlertMetricStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RegionalAlertMetricStatus.`open`) }
    }
}
