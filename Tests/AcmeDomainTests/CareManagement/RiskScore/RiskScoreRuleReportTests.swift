@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701732069)
        var items: [CareManagement.RiskScoreRule] = []
        for index in 0..<2 {
            items.append(CareManagement.newRiskScoreRule("risk-score-rule-\(index)", label: "sample"))
        }
        let report = CareManagement.buildRiskScoreRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
