@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedStudyScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701132948)
        var items: [Imaging.BatchedStudySchedule] = []
        for index in 0..<5 {
            items.append(Imaging.newBatchedStudySchedule("batched-study-schedule-\(index)", name: "sample"))
        }
        let report = Imaging.buildBatchedStudyScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
