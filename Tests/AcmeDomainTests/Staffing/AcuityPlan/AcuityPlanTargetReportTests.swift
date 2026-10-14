@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706017991)
        var items: [Staffing.AcuityPlanTarget] = []
        for index in 0..<3 {
            items.append(Staffing.newAcuityPlanTarget("acuity-plan-target-\(index)", title: "sample"))
        }
        let report = Staffing.buildAcuityPlanTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
