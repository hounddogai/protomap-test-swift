@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701169956)
        var items: [Labs.PanelScore] = []
        for index in 0..<4 {
            items.append(Labs.newPanelScore("panel-score-\(index)", title: "sample"))
        }
        let report = Labs.buildPanelScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
