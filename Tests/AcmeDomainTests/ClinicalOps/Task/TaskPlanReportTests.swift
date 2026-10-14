@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703247813)
        var items: [ClinicalOps.TaskPlan] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newTaskPlan("task-plan-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildTaskPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
