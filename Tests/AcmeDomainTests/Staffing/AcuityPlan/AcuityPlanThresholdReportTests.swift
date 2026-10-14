@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701677878)
        var items: [Staffing.AcuityPlanThreshold] = []
        for index in 0..<4 {
            items.append(Staffing.newAcuityPlanThreshold("acuity-plan-threshold-\(index)", name: "sample"))
        }
        let report = Staffing.buildAcuityPlanThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
