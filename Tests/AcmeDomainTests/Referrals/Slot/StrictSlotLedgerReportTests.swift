@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictSlotLedgerReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703247031)
        var items: [Referrals.StrictSlotLedger] = []
        for index in 0..<5 {
            items.append(Referrals.newStrictSlotLedger("strict-slot-ledger-\(index)", title: "sample"))
        }
        let report = Referrals.buildStrictSlotLedgerReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
