@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingRoundingLedgerReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700576241)
        var items: [ClinicalOps.PendingRoundingLedger] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newPendingRoundingLedger("pending-rounding-ledger-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildPendingRoundingLedgerReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
