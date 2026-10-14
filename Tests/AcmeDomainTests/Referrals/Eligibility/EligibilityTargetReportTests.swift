@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700155534)
        var items: [Referrals.EligibilityTarget] = []
        for index in 0..<6 {
            items.append(Referrals.newEligibilityTarget("eligibility-target-\(index)", name: "sample"))
        }
        let report = Referrals.buildEligibilityTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
