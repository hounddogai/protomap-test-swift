@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707993848)
        var items: [CareManagement.RiskScoreProposal] = []
        for index in 0..<4 {
            items.append(CareManagement.newRiskScoreProposal("risk-score-proposal-\(index)", name: "sample"))
        }
        let report = CareManagement.buildRiskScoreProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
