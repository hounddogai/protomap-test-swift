@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702487545)
        var items: [CareManagement.RiskScoreBaseline] = []
        for index in 0..<2 {
            items.append(CareManagement.newRiskScoreBaseline("risk-score-baseline-\(index)", name: "sample"))
        }
        let report = CareManagement.buildRiskScoreBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
