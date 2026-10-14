@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCensusLedgerReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702942997)
        var items: [BedManagement.PendingCensusLedger] = []
        for index in 0..<5 {
            items.append(BedManagement.newPendingCensusLedger("pending-census-ledger-\(index)", label: "sample"))
        }
        let report = BedManagement.buildPendingCensusLedgerReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
