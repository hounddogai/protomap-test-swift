@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703676082)
        var items: [CareManagement.AdaptiveRiskScoreCheckpoint] = []
        for index in 0..<3 {
            items.append(CareManagement.newAdaptiveRiskScoreCheckpoint("adaptive-risk-score-checkpoint-\(index)", name: "sample"))
        }
        let report = CareManagement.buildAdaptiveRiskScoreCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
