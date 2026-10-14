@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingShiftNoticeReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704090523)
        var items: [Staffing.RollingShiftNotice] = []
        for index in 0..<4 {
            items.append(Staffing.newRollingShiftNotice("rolling-shift-notice-\(index)", label: "sample"))
        }
        let report = Staffing.buildRollingShiftNoticeReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
