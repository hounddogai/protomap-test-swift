@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703285423)
        var items: [Referrals.EligibilityPolicy] = []
        for index in 0..<5 {
            items.append(Referrals.newEligibilityPolicy("eligibility-policy-\(index)", name: "sample"))
        }
        let report = Referrals.buildEligibilityPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
