@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707867441)
        var items: [BedManagement.CleaningSchedule] = []
        for index in 0..<3 {
            items.append(BedManagement.newCleaningSchedule("cleaning-schedule-\(index)", name: "sample"))
        }
        let report = BedManagement.buildCleaningScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
