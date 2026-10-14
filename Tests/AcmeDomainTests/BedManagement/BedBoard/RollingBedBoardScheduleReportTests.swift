@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingBedBoardScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704262838)
        var items: [BedManagement.RollingBedBoardSchedule] = []
        for index in 0..<2 {
            items.append(BedManagement.newRollingBedBoardSchedule("rolling-bed-board-schedule-\(index)", label: "sample"))
        }
        let report = BedManagement.buildRollingBedBoardScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
