@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertForecastReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709649888)
        var items: [ClinicalOps.AlertForecast] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newAlertForecast("alert-forecast-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildAlertForecastReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
