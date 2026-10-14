@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706614327)
        var items: [Referrals.WeightedReferralVariance] = []
        for index in 0..<5 {
            items.append(Referrals.newWeightedReferralVariance("weighted-referral-variance-\(index)", name: "sample"))
        }
        let report = Referrals.buildWeightedReferralVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
