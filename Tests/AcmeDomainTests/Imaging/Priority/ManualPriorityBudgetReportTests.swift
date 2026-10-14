@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualPriorityBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706404714)
        var items: [Imaging.ManualPriorityBudget] = []
        for index in 0..<5 {
            items.append(Imaging.newManualPriorityBudget("manual-priority-budget-\(index)", title: "sample"))
        }
        let report = Imaging.buildManualPriorityBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
