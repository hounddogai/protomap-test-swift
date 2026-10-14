@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703197329)
        var items: [Labs.ResultBudget] = []
        for index in 0..<2 {
            items.append(Labs.newResultBudget("result-budget-\(index)", title: "sample"))
        }
        let report = Labs.buildResultBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
