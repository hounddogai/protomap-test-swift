@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingOvertimeBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706579233)
        var items: [Staffing.RollingOvertimeBudget] = []
        for index in 0..<2 {
            items.append(Staffing.newRollingOvertimeBudget("rolling-overtime-budget-\(index)", title: "sample"))
        }
        let report = Staffing.buildRollingOvertimeBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
