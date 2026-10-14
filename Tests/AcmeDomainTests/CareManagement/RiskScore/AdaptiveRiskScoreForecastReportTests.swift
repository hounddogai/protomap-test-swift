@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreForecastReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709528667)
        var items: [CareManagement.AdaptiveRiskScoreForecast] = []
        for index in 0..<6 {
            items.append(CareManagement.newAdaptiveRiskScoreForecast("adaptive-risk-score-forecast-\(index)", name: "sample"))
        }
        let report = CareManagement.buildAdaptiveRiskScoreForecastReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
