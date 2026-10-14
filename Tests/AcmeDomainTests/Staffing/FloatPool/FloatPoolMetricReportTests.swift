@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700185662)
        var items: [Staffing.FloatPoolMetric] = []
        for index in 0..<3 {
            items.append(Staffing.newFloatPoolMetric("float-pool-metric-\(index)", title: "sample"))
        }
        let report = Staffing.buildFloatPoolMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
