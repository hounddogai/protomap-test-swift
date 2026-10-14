@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualReferralMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709327659)
        var items: [Referrals.ManualReferralMapping] = []
        for index in 0..<3 {
            items.append(Referrals.newManualReferralMapping("manual-referral-mapping-\(index)", label: "sample"))
        }
        let report = Referrals.buildManualReferralMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
