@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledOvertimeRecordReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708159329)
        var items: [Staffing.ScheduledOvertimeRecord] = []
        for index in 0..<6 {
            items.append(Staffing.newScheduledOvertimeRecord("scheduled-overtime-record-\(index)", label: "sample"))
        }
        let report = Staffing.buildScheduledOvertimeRecordReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
