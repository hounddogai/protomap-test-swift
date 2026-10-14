@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyOrderSetMetricTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newLegacyOrderSetMetric("code-692", name: "name-378")
        #expect(item.status == ClinicalOps.LegacyOrderSetMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newLegacyOrderSetMetric("code-692", name: "name-378")
        try item.moveTo(ClinicalOps.LegacyOrderSetMetricStatus.granted)
        #expect(item.status == ClinicalOps.LegacyOrderSetMetricStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newLegacyOrderSetMetric("code-692", name: "name-378")
        item.status = ClinicalOps.LegacyOrderSetMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LegacyOrderSetMetricStatus.requested) }
    }
}
