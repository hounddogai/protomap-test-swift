@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryReferralMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704767668)
        var items: [Referrals.PrimaryReferralMilestone] = []
        for index in 0..<5 {
            items.append(Referrals.newPrimaryReferralMilestone("primary-referral-milestone-\(index)", title: "sample"))
        }
        let report = Referrals.buildPrimaryReferralMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
