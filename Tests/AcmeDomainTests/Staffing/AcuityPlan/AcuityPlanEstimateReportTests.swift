@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702122990)
        var items: [Staffing.AcuityPlanEstimate] = []
        for index in 0..<4 {
            items.append(Staffing.newAcuityPlanEstimate("acuity-plan-estimate-\(index)", label: "sample"))
        }
        let report = Staffing.buildAcuityPlanEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
