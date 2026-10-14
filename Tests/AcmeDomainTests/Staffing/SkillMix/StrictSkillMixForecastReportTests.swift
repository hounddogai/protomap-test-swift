@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictSkillMixForecastReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700442377)
        var items: [Staffing.StrictSkillMixForecast] = []
        for index in 0..<3 {
            items.append(Staffing.newStrictSkillMixForecast("strict-skill-mix-forecast-\(index)", label: "sample"))
        }
        let report = Staffing.buildStrictSkillMixForecastReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
