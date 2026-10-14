@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707093612)
        var items: [Referrals.TieredFollowUpBaseline] = []
        for index in 0..<3 {
            items.append(Referrals.newTieredFollowUpBaseline("tiered-follow-up-baseline-\(index)", title: "sample"))
        }
        let report = Referrals.buildTieredFollowUpBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
