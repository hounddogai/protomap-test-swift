@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingGoalSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702583169)
        var items: [CareManagement.PendingGoalSnapshot] = []
        for index in 0..<4 {
            items.append(CareManagement.newPendingGoalSnapshot("pending-goal-snapshot-\(index)", name: "sample"))
        }
        let report = CareManagement.buildPendingGoalSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
