@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultCourierMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705304283)
        var items: [Labs.DefaultCourierMetric] = []
        for index in 0..<4 {
            items.append(Labs.newDefaultCourierMetric("default-courier-metric-\(index)", label: "sample"))
        }
        let report = Labs.buildDefaultCourierMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
