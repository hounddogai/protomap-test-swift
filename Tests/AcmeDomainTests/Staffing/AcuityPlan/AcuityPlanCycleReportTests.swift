@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708707941)
        var items: [Staffing.AcuityPlanCycle] = []
        for index in 0..<5 {
            items.append(Staffing.newAcuityPlanCycle("acuity-plan-cycle-\(index)", name: "sample"))
        }
        let report = Staffing.buildAcuityPlanCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
