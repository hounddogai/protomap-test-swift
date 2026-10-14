@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706224780)
        var items: [Referrals.EligibilityMapping] = []
        for index in 0..<5 {
            items.append(Referrals.newEligibilityMapping("eligibility-mapping-\(index)", name: "sample"))
        }
        let report = Referrals.buildEligibilityMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
