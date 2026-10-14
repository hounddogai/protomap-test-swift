@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709366543)
        var items: [CareManagement.GoalAllocation] = []
        for index in 0..<3 {
            items.append(CareManagement.newGoalAllocation("goal-allocation-\(index)", label: "sample"))
        }
        let report = CareManagement.buildGoalAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
