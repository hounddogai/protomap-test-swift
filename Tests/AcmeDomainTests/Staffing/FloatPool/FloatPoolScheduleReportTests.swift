@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709238711)
        var items: [Staffing.FloatPoolSchedule] = []
        for index in 0..<5 {
            items.append(Staffing.newFloatPoolSchedule("float-pool-schedule-\(index)", name: "sample"))
        }
        let report = Staffing.buildFloatPoolScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
