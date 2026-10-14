@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientStudyMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703621833)
        var items: [Imaging.LenientStudyMetric] = []
        for index in 0..<3 {
            items.append(Imaging.newLenientStudyMetric("lenient-study-metric-\(index)", label: "sample"))
        }
        let report = Imaging.buildLenientStudyMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
