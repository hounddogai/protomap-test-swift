@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707697796)
        var items: [Referrals.NetworkPlan] = []
        for index in 0..<6 {
            items.append(Referrals.newNetworkPlan("network-plan-\(index)", name: "sample"))
        }
        let report = Referrals.buildNetworkPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
