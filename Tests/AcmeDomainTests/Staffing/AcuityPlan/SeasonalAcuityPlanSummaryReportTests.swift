@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalAcuityPlanSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705542707)
        var items: [Staffing.SeasonalAcuityPlanSummary] = []
        for index in 0..<2 {
            items.append(Staffing.newSeasonalAcuityPlanSummary("seasonal-acuity-plan-summary-\(index)", name: "sample"))
        }
        let report = Staffing.buildSeasonalAcuityPlanSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
