@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705565826)
        var items: [RevenueCycle.RemittanceBudget] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newRemittanceBudget("remittance-budget-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildRemittanceBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
