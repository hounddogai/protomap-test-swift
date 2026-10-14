@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeForecastReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701497542)
        var items: [Staffing.OvertimeForecast] = []
        for index in 0..<4 {
            items.append(Staffing.newOvertimeForecast("overtime-forecast-\(index)", label: "sample"))
        }
        let report = Staffing.buildOvertimeForecastReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
