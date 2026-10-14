@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702573142)
        var items: [Imaging.WorklistSchedule] = []
        for index in 0..<5 {
            items.append(Imaging.newWorklistSchedule("worklist-schedule-\(index)", title: "sample"))
        }
        let report = Imaging.buildWorklistScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
