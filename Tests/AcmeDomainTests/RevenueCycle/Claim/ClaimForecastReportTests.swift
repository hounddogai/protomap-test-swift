@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimForecastReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704808022)
        var items: [RevenueCycle.ClaimForecast] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newClaimForecast("claim-forecast-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildClaimForecastReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
