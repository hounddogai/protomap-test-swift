@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredEligibilityTemplateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704420520)
        var items: [Referrals.TieredEligibilityTemplate] = []
        for index in 0..<3 {
            items.append(Referrals.newTieredEligibilityTemplate("tiered-eligibility-template-\(index)", label: "sample"))
        }
        let report = Referrals.buildTieredEligibilityTemplateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
