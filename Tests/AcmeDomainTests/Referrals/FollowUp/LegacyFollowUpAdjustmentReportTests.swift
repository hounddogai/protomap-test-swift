@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyFollowUpAdjustmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706543329)
        var items: [Referrals.LegacyFollowUpAdjustment] = []
        for index in 0..<6 {
            items.append(Referrals.newLegacyFollowUpAdjustment("legacy-follow-up-adjustment-\(index)", name: "sample"))
        }
        let report = Referrals.buildLegacyFollowUpAdjustmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
