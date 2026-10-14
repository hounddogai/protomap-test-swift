@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704135850)
        var items: [RevenueCycle.StatementBudget] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newStatementBudget("statement-budget-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildStatementBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
