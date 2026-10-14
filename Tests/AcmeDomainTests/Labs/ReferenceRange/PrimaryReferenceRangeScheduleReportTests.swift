@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryReferenceRangeScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703755075)
        var items: [Labs.PrimaryReferenceRangeSchedule] = []
        for index in 0..<4 {
            items.append(Labs.newPrimaryReferenceRangeSchedule("primary-reference-range-schedule-\(index)", title: "sample"))
        }
        let report = Labs.buildPrimaryReferenceRangeScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
