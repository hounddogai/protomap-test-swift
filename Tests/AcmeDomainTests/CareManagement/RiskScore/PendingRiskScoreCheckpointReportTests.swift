@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingRiskScoreCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701099014)
        var items: [CareManagement.PendingRiskScoreCheckpoint] = []
        for index in 0..<2 {
            items.append(CareManagement.newPendingRiskScoreCheckpoint("pending-risk-score-checkpoint-\(index)", label: "sample"))
        }
        let report = CareManagement.buildPendingRiskScoreCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
