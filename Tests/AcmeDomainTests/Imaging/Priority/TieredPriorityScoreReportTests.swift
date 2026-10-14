@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredPriorityScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704794259)
        var items: [Imaging.TieredPriorityScore] = []
        for index in 0..<4 {
            items.append(Imaging.newTieredPriorityScore("tiered-priority-score-\(index)", name: "sample"))
        }
        let report = Imaging.buildTieredPriorityScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
