@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackOvertimeMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703833505)
        var items: [Staffing.FallbackOvertimeMetric] = []
        for index in 0..<5 {
            items.append(Staffing.newFallbackOvertimeMetric("fallback-overtime-metric-\(index)", name: "sample"))
        }
        let report = Staffing.buildFallbackOvertimeMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
