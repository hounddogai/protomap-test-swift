@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalNetworkScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700999201)
        var items: [Referrals.GlobalNetworkScore] = []
        for index in 0..<2 {
            items.append(Referrals.newGlobalNetworkScore("global-network-score-\(index)", label: "sample"))
        }
        let report = Referrals.buildGlobalNetworkScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
