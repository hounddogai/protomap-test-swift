@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706657908)
        var items: [ClinicalOps.TaskSegment] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newTaskSegment("task-segment-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildTaskSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
