@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalSkillMixLedgerReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703649739)
        var items: [Staffing.RegionalSkillMixLedger] = []
        for index in 0..<2 {
            items.append(Staffing.newRegionalSkillMixLedger("regional-skill-mix-ledger-\(index)", title: "sample"))
        }
        let report = Staffing.buildRegionalSkillMixLedgerReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
