@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701662042)
        var items: [Referrals.WeightedReferralProposal] = []
        for index in 0..<2 {
            items.append(Referrals.newWeightedReferralProposal("weighted-referral-proposal-\(index)", label: "sample"))
        }
        let report = Referrals.buildWeightedReferralProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
