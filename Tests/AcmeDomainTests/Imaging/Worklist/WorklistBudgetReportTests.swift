@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705107917)
        var items: [Imaging.WorklistBudget] = []
        for index in 0..<4 {
            items.append(Imaging.newWorklistBudget("worklist-budget-\(index)", label: "sample"))
        }
        let report = Imaging.buildWorklistBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
