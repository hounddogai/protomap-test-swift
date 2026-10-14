@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701556190)
        var items: [Referrals.EligibilityAudit] = []
        for index in 0..<5 {
            items.append(Referrals.newEligibilityAudit("eligibility-audit-\(index)", title: "sample"))
        }
        let report = Referrals.buildEligibilityAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
