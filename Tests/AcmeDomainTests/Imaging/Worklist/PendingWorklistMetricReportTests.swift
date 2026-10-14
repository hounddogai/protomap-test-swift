@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingWorklistMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701211260)
        var items: [Imaging.PendingWorklistMetric] = []
        for index in 0..<2 {
            items.append(Imaging.newPendingWorklistMetric("pending-worklist-metric-\(index)", label: "sample"))
        }
        let report = Imaging.buildPendingWorklistMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
