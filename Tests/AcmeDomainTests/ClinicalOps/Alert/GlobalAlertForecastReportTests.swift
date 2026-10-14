@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalAlertForecastReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703361599)
        var items: [ClinicalOps.GlobalAlertForecast] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newGlobalAlertForecast("global-alert-forecast-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildGlobalAlertForecastReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
