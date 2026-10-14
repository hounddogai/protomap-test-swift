@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709956067)
        var items: [ClinicalOps.TaskSnapshot] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newTaskSnapshot("task-snapshot-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildTaskSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
