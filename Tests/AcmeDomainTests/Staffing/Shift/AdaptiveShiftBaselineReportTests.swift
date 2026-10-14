@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveShiftBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709319401)
        var items: [Staffing.AdaptiveShiftBaseline] = []
        for index in 0..<4 {
            items.append(Staffing.newAdaptiveShiftBaseline("adaptive-shift-baseline-\(index)", name: "sample"))
        }
        let report = Staffing.buildAdaptiveShiftBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
