@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedCourierMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703336845)
        var items: [Labs.CappedCourierMetric] = []
        for index in 0..<2 {
            items.append(Labs.newCappedCourierMetric("capped-courier-metric-\(index)", name: "sample"))
        }
        let report = Labs.buildCappedCourierMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
