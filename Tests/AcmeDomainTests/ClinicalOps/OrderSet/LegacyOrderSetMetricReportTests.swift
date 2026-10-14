@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyOrderSetMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701323930)
        var items: [ClinicalOps.LegacyOrderSetMetric] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newLegacyOrderSetMetric("legacy-order-set-metric-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildLegacyOrderSetMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
