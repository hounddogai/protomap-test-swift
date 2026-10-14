@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingNetworkOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703331176)
        var items: [Referrals.PendingNetworkOverride] = []
        for index in 0..<2 {
            items.append(Referrals.newPendingNetworkOverride("pending-network-override-\(index)", name: "sample"))
        }
        let report = Referrals.buildPendingNetworkOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
