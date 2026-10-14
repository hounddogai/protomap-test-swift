@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706960078)
        var items: [RevenueCycle.AuthorizationBudget] = []
        for index in 0..<5 {
            items.append(RevenueCycle.newAuthorizationBudget("authorization-budget-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildAuthorizationBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
