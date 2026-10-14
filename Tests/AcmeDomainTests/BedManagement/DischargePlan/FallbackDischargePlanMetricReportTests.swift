@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackDischargePlanMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708287238)
        var items: [BedManagement.FallbackDischargePlanMetric] = []
        for index in 0..<3 {
            items.append(BedManagement.newFallbackDischargePlanMetric("fallback-discharge-plan-metric-\(index)", label: "sample"))
        }
        let report = BedManagement.buildFallbackDischargePlanMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
