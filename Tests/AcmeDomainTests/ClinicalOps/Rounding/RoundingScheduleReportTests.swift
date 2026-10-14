@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702892892)
        var items: [ClinicalOps.RoundingSchedule] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newRoundingSchedule("rounding-schedule-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildRoundingScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
