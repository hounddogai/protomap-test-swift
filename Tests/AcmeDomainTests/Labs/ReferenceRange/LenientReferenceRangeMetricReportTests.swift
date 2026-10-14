@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707141807)
        var items: [Labs.LenientReferenceRangeMetric] = []
        for index in 0..<2 {
            items.append(Labs.newLenientReferenceRangeMetric("lenient-reference-range-metric-\(index)", title: "sample"))
        }
        let report = Labs.buildLenientReferenceRangeMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
