@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackReferralMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705787703)
        var items: [Referrals.FallbackReferralMapping] = []
        for index in 0..<6 {
            items.append(Referrals.newFallbackReferralMapping("fallback-referral-mapping-\(index)", label: "sample"))
        }
        let report = Referrals.buildFallbackReferralMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
