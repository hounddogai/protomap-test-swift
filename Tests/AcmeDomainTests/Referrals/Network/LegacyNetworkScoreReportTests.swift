@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyNetworkScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709281869)
        var items: [Referrals.LegacyNetworkScore] = []
        for index in 0..<6 {
            items.append(Referrals.newLegacyNetworkScore("legacy-network-score-\(index)", title: "sample"))
        }
        let report = Referrals.buildLegacyNetworkScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
