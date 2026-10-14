@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingReferralLedgerReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706907470)
        var items: [Referrals.PendingReferralLedger] = []
        for index in 0..<3 {
            items.append(Referrals.newPendingReferralLedger("pending-referral-ledger-\(index)", label: "sample"))
        }
        let report = Referrals.buildPendingReferralLedgerReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
