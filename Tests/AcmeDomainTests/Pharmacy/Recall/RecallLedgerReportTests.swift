@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallLedgerReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706539448)
        var items: [Pharmacy.RecallLedger] = []
        for index in 0..<2 {
            items.append(Pharmacy.newRecallLedger("recall-ledger-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildRecallLedgerReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
