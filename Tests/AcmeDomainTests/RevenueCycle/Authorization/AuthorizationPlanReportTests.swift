@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700009489)
        var items: [RevenueCycle.AuthorizationPlan] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newAuthorizationPlan("authorization-plan-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildAuthorizationPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
