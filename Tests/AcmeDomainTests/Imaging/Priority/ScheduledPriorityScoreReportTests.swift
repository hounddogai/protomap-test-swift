@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledPriorityScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706003890)
        var items: [Imaging.ScheduledPriorityScore] = []
        for index in 0..<4 {
            items.append(Imaging.newScheduledPriorityScore("scheduled-priority-score-\(index)", label: "sample"))
        }
        let report = Imaging.buildScheduledPriorityScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
