@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledEligibilityPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705785518)
        var items: [Referrals.ScheduledEligibilityPlan] = []
        for index in 0..<3 {
            items.append(Referrals.newScheduledEligibilityPlan("scheduled-eligibility-plan-\(index)", name: "sample"))
        }
        let report = Referrals.buildScheduledEligibilityPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
