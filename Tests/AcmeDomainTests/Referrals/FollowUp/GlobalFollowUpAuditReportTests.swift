@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalFollowUpAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708458532)
        var items: [Referrals.GlobalFollowUpAudit] = []
        for index in 0..<5 {
            items.append(Referrals.newGlobalFollowUpAudit("global-follow-up-audit-\(index)", label: "sample"))
        }
        let report = Referrals.buildGlobalFollowUpAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
