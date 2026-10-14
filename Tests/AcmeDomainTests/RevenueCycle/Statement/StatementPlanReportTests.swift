@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709309061)
        var items: [RevenueCycle.StatementPlan] = []
        for index in 0..<5 {
            items.append(RevenueCycle.newStatementPlan("statement-plan-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildStatementPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
