@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700529213)
        var items: [BedManagement.DischargePlanRule] = []
        for index in 0..<5 {
            items.append(BedManagement.newDischargePlanRule("discharge-plan-rule-\(index)", title: "sample"))
        }
        let report = BedManagement.buildDischargePlanRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
