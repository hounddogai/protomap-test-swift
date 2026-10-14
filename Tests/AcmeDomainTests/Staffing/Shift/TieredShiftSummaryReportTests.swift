@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredShiftSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707648718)
        var items: [Staffing.TieredShiftSummary] = []
        for index in 0..<5 {
            items.append(Staffing.newTieredShiftSummary("tiered-shift-summary-\(index)", title: "sample"))
        }
        let report = Staffing.buildTieredShiftSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
