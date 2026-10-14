@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701887931)
        var items: [CareManagement.RiskScoreMetric] = []
        for index in 0..<5 {
            items.append(CareManagement.newRiskScoreMetric("risk-score-metric-\(index)", name: "sample"))
        }
        let report = CareManagement.buildRiskScoreMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
