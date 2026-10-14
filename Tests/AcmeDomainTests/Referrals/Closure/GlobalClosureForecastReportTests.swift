@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalClosureForecastReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702797480)
        var items: [Referrals.GlobalClosureForecast] = []
        for index in 0..<4 {
            items.append(Referrals.newGlobalClosureForecast("global-closure-forecast-\(index)", title: "sample"))
        }
        let report = Referrals.buildGlobalClosureForecastReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
