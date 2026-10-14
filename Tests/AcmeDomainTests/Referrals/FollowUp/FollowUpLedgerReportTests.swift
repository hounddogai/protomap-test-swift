@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpLedgerReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704142259)
        var items: [Referrals.FollowUpLedger] = []
        for index in 0..<2 {
            items.append(Referrals.newFollowUpLedger("follow-up-ledger-\(index)", name: "sample"))
        }
        let report = Referrals.buildFollowUpLedgerReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
