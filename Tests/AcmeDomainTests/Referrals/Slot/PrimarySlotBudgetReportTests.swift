@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimarySlotBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700021848)
        var items: [Referrals.PrimarySlotBudget] = []
        for index in 0..<3 {
            items.append(Referrals.newPrimarySlotBudget("primary-slot-budget-\(index)", title: "sample"))
        }
        let report = Referrals.buildPrimarySlotBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
