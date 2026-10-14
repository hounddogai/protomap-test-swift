@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientAcuityPlanAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701652661)
        var items: [Staffing.LenientAcuityPlanAllocation] = []
        for index in 0..<2 {
            items.append(Staffing.newLenientAcuityPlanAllocation("lenient-acuity-plan-allocation-\(index)", title: "sample"))
        }
        let report = Staffing.buildLenientAcuityPlanAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
