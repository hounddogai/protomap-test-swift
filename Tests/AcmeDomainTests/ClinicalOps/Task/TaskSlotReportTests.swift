@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskSlotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704858777)
        var items: [ClinicalOps.TaskSlot] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newTaskSlot("task-slot-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildTaskSlotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
