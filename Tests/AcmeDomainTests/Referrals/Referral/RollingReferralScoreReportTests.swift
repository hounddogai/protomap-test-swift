@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingReferralScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701263085)
        var items: [Referrals.RollingReferralScore] = []
        for index in 0..<4 {
            items.append(Referrals.newRollingReferralScore("rolling-referral-score-\(index)", label: "sample"))
        }
        let report = Referrals.buildRollingReferralScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
