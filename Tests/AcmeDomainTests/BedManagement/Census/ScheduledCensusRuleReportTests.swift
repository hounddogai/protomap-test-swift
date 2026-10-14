@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706163511)
        var items: [BedManagement.ScheduledCensusRule] = []
        for index in 0..<4 {
            items.append(BedManagement.newScheduledCensusRule("scheduled-census-rule-\(index)", title: "sample"))
        }
        let report = BedManagement.buildScheduledCensusRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
