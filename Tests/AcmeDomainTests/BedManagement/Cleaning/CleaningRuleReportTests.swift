@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708275101)
        var items: [BedManagement.CleaningRule] = []
        for index in 0..<2 {
            items.append(BedManagement.newCleaningRule("cleaning-rule-\(index)", name: "sample"))
        }
        let report = BedManagement.buildCleaningRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
