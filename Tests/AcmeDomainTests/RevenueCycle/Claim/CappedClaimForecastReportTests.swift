@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedClaimForecastReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709020563)
        var items: [RevenueCycle.CappedClaimForecast] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newCappedClaimForecast("capped-claim-forecast-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildCappedClaimForecastReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
