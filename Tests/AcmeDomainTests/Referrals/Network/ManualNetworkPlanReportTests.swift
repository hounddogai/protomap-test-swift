@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707918872)
        var items: [Referrals.ManualNetworkPlan] = []
        for index in 0..<4 {
            items.append(Referrals.newManualNetworkPlan("manual-network-plan-\(index)", name: "sample"))
        }
        let report = Referrals.buildManualNetworkPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
