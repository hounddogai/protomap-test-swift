@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704665310)
        var items: [BedManagement.IsolationMetric] = []
        for index in 0..<4 {
            items.append(BedManagement.newIsolationMetric("isolation-metric-\(index)", name: "sample"))
        }
        let report = BedManagement.buildIsolationMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
