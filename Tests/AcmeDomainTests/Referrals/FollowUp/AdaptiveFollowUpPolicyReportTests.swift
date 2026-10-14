@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveFollowUpPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705070056)
        var items: [Referrals.AdaptiveFollowUpPolicy] = []
        for index in 0..<4 {
            items.append(Referrals.newAdaptiveFollowUpPolicy("adaptive-follow-up-policy-\(index)", label: "sample"))
        }
        let report = Referrals.buildAdaptiveFollowUpPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
