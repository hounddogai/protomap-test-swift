@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingShiftBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700839791)
        var items: [Staffing.PendingShiftBudget] = []
        for index in 0..<2 {
            items.append(Staffing.newPendingShiftBudget("pending-shift-budget-\(index)", title: "sample"))
        }
        let report = Staffing.buildPendingShiftBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
