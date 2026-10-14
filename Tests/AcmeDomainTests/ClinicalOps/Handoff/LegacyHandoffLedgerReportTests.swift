@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyHandoffLedgerReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708261228)
        var items: [ClinicalOps.LegacyHandoffLedger] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newLegacyHandoffLedger("legacy-handoff-ledger-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildLegacyHandoffLedgerReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
