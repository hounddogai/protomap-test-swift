@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703423738)
        var items: [Staffing.PrimaryAcuityPlanTarget] = []
        for index in 0..<5 {
            items.append(Staffing.newPrimaryAcuityPlanTarget("primary-acuity-plan-target-\(index)", title: "sample"))
        }
        let report = Staffing.buildPrimaryAcuityPlanTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
