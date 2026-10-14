@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedStatementForecastReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709133372)
        var items: [RevenueCycle.CappedStatementForecast] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newCappedStatementForecast("capped-statement-forecast-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildCappedStatementForecastReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
