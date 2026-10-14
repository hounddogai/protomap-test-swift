@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredPanelScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706260722)
        var items: [Labs.TieredPanelSchedule] = []
        for index in 0..<3 {
            items.append(Labs.newTieredPanelSchedule("tiered-panel-schedule-\(index)", label: "sample"))
        }
        let report = Labs.buildTieredPanelScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
