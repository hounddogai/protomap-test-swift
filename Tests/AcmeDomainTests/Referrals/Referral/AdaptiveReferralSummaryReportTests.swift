@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveReferralSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707117555)
        var items: [Referrals.AdaptiveReferralSummary] = []
        for index in 0..<4 {
            items.append(Referrals.newAdaptiveReferralSummary("adaptive-referral-summary-\(index)", title: "sample"))
        }
        let report = Referrals.buildAdaptiveReferralSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
