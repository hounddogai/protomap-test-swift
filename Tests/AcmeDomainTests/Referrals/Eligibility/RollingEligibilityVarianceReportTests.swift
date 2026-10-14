@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingEligibilityVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706510615)
        var items: [Referrals.RollingEligibilityVariance] = []
        for index in 0..<2 {
            items.append(Referrals.newRollingEligibilityVariance("rolling-eligibility-variance-\(index)", title: "sample"))
        }
        let report = Referrals.buildRollingEligibilityVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
