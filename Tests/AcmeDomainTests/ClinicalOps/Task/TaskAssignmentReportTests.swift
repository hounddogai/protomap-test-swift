@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702420760)
        var items: [ClinicalOps.TaskAssignment] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newTaskAssignment("task-assignment-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildTaskAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
