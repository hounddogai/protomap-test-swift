@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalEligibilityForecastReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707217006)
        var items: [Referrals.GlobalEligibilityForecast] = []
        for index in 0..<3 {
            items.append(Referrals.newGlobalEligibilityForecast("global-eligibility-forecast-\(index)", label: "sample"))
        }
        let report = Referrals.buildGlobalEligibilityForecastReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
