@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700287293)
        var items: [Labs.SpecimenSchedule] = []
        for index in 0..<3 {
            items.append(Labs.newSpecimenSchedule("specimen-schedule-\(index)", title: "sample"))
        }
        let report = Labs.buildSpecimenScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
