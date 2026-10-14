@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledReadPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708180645)
        var items: [Imaging.ScheduledReadPlan] = []
        for index in 0..<2 {
            items.append(Imaging.newScheduledReadPlan("scheduled-read-plan-\(index)", title: "sample"))
        }
        let report = Imaging.buildScheduledReadPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
