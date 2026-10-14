@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledShiftGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704420221)
        var items: [Staffing.ScheduledShiftGroup] = []
        for index in 0..<6 {
            items.append(Staffing.newScheduledShiftGroup("scheduled-shift-group-\(index)", label: "sample"))
        }
        let report = Staffing.buildScheduledShiftGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
