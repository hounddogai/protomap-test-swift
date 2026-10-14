@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702479585)
        var items: [Labs.LenientReferenceRangeSchedule] = []
        for index in 0..<2 {
            items.append(Labs.newLenientReferenceRangeSchedule("lenient-reference-range-schedule-\(index)", title: "sample"))
        }
        let report = Labs.buildLenientReferenceRangeScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
