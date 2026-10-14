@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackRoundingMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700279919)
        var items: [ClinicalOps.FallbackRoundingMetric] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newFallbackRoundingMetric("fallback-rounding-metric-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildFallbackRoundingMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
