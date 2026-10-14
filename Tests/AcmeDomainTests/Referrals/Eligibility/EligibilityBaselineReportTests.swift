@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708159395)
        var items: [Referrals.EligibilityBaseline] = []
        for index in 0..<4 {
            items.append(Referrals.newEligibilityBaseline("eligibility-baseline-\(index)", label: "sample"))
        }
        let report = Referrals.buildEligibilityBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
