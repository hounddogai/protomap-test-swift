@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalOvertimeLedgerReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701508061)
        var items: [Staffing.GlobalOvertimeLedger] = []
        for index in 0..<2 {
            items.append(Staffing.newGlobalOvertimeLedger("global-overtime-ledger-\(index)", name: "sample"))
        }
        let report = Staffing.buildGlobalOvertimeLedgerReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
