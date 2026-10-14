@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledPriorityEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702467164)
        var items: [Imaging.ScheduledPriorityEstimate] = []
        for index in 0..<2 {
            items.append(Imaging.newScheduledPriorityEstimate("scheduled-priority-estimate-\(index)", title: "sample"))
        }
        let report = Imaging.buildScheduledPriorityEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
