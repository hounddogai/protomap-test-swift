@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709076545)
        var items: [RevenueCycle.ChargeBudget] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newChargeBudget("charge-budget-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildChargeBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
