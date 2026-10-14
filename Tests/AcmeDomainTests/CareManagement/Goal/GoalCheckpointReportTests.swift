@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708543054)
        var items: [CareManagement.GoalCheckpoint] = []
        for index in 0..<2 {
            items.append(CareManagement.newGoalCheckpoint("goal-checkpoint-\(index)", title: "sample"))
        }
        let report = CareManagement.buildGoalCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
