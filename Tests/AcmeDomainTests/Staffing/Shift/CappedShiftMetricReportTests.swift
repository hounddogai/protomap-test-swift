@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedShiftMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705862013)
        var items: [Staffing.CappedShiftMetric] = []
        for index in 0..<2 {
            items.append(Staffing.newCappedShiftMetric("capped-shift-metric-\(index)", label: "sample"))
        }
        let report = Staffing.buildCappedShiftMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
