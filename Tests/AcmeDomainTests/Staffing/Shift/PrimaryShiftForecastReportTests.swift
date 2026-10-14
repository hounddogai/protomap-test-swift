@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryShiftForecastReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708226349)
        var items: [Staffing.PrimaryShiftForecast] = []
        for index in 0..<5 {
            items.append(Staffing.newPrimaryShiftForecast("primary-shift-forecast-\(index)", label: "sample"))
        }
        let report = Staffing.buildPrimaryShiftForecastReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
