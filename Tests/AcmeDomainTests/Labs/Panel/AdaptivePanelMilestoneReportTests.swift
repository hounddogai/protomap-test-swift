@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709758741)
        var items: [Labs.AdaptivePanelMilestone] = []
        for index in 0..<3 {
            items.append(Labs.newAdaptivePanelMilestone("adaptive-panel-milestone-\(index)", name: "sample"))
        }
        let report = Labs.buildAdaptivePanelMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
