@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedReferralRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700713757)
        var items: [Referrals.CappedReferralRollup] = []
        for index in 0..<2 {
            items.append(Referrals.newCappedReferralRollup("capped-referral-rollup-\(index)", title: "sample"))
        }
        let report = Referrals.buildCappedReferralRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
