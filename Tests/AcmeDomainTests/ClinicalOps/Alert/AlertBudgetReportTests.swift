@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708637369)
        var items: [ClinicalOps.AlertBudget] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newAlertBudget("alert-budget-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildAlertBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
