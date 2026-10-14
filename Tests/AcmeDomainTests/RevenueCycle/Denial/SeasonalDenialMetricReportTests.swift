@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleSeasonalDenialMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702476320)
        var items: [RevenueCycle.SeasonalDenialMetric] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newSeasonalDenialMetric("seasonal-denial-metric-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildSeasonalDenialMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
