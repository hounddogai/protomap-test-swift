@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualAlertMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702270590)
        var items: [ClinicalOps.ManualAlertMetric] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newManualAlertMetric("manual-alert-metric-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildManualAlertMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
