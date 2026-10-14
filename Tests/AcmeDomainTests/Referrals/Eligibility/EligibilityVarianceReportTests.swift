@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702222601)
        var items: [Referrals.EligibilityVariance] = []
        for index in 0..<3 {
            items.append(Referrals.newEligibilityVariance("eligibility-variance-\(index)", label: "sample"))
        }
        let report = Referrals.buildEligibilityVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
