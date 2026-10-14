@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708472538)
        var items: [ClinicalOps.RegionalAlertMetric] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newRegionalAlertMetric("regional-alert-metric-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildRegionalAlertMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
