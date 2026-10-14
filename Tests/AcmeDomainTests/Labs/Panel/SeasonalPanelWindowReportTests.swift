@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalPanelWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700019049)
        var items: [Labs.SeasonalPanelWindow] = []
        for index in 0..<3 {
            items.append(Labs.newSeasonalPanelWindow("seasonal-panel-window-\(index)", name: "sample"))
        }
        let report = Labs.buildSeasonalPanelWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
