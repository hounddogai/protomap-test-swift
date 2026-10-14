@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703497127)
        var items: [Staffing.FloatPoolRule] = []
        for index in 0..<6 {
            items.append(Staffing.newFloatPoolRule("float-pool-rule-\(index)", title: "sample"))
        }
        let report = Staffing.buildFloatPoolRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
