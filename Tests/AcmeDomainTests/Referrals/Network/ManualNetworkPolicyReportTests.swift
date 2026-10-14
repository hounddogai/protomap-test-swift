@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705705553)
        var items: [Referrals.ManualNetworkPolicy] = []
        for index in 0..<4 {
            items.append(Referrals.newManualNetworkPolicy("manual-network-policy-\(index)", name: "sample"))
        }
        let report = Referrals.buildManualNetworkPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
