@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledPanelScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701396175)
        var items: [Labs.ScheduledPanelScore] = []
        for index in 0..<2 {
            items.append(Labs.newScheduledPanelScore("scheduled-panel-score-\(index)", name: "sample"))
        }
        let report = Labs.buildScheduledPanelScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
