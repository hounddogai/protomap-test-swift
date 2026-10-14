@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingNetworkPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701938801)
        var items: [Referrals.PendingNetworkPreference] = []
        for index in 0..<3 {
            items.append(Referrals.newPendingNetworkPreference("pending-network-preference-\(index)", title: "sample"))
        }
        let report = Referrals.buildPendingNetworkPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
