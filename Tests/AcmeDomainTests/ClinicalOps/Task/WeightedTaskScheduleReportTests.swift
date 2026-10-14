@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedTaskScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703004267)
        var items: [ClinicalOps.WeightedTaskSchedule] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newWeightedTaskSchedule("weighted-task-schedule-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildWeightedTaskScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
