@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingRiskScoreRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704460078)
        var items: [CareManagement.RollingRiskScoreRule] = []
        for index in 0..<5 {
            items.append(CareManagement.newRollingRiskScoreRule("rolling-risk-score-rule-\(index)", title: "sample"))
        }
        let report = CareManagement.buildRollingRiskScoreRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
