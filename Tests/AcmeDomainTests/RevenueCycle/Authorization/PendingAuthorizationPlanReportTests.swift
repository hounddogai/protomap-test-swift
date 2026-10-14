@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingAuthorizationPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702227639)
        var items: [RevenueCycle.PendingAuthorizationPlan] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newPendingAuthorizationPlan("pending-authorization-plan-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildPendingAuthorizationPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
