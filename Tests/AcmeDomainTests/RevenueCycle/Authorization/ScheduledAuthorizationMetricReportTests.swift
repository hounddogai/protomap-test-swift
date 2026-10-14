@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledAuthorizationMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703344142)
        var items: [RevenueCycle.ScheduledAuthorizationMetric] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newScheduledAuthorizationMetric("scheduled-authorization-metric-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildScheduledAuthorizationMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
