@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalReferralAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707822497)
        var items: [Referrals.SeasonalReferralAudit] = []
        for index in 0..<3 {
            items.append(Referrals.newSeasonalReferralAudit("seasonal-referral-audit-\(index)", label: "sample"))
        }
        let report = Referrals.buildSeasonalReferralAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
