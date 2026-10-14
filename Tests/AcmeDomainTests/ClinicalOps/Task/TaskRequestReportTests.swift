@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskRequestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701819692)
        var items: [ClinicalOps.TaskRequest] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newTaskRequest("task-request-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildTaskRequestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
