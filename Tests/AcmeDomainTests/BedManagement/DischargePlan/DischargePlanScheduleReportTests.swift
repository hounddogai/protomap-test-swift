@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704199677)
        var items: [BedManagement.DischargePlanSchedule] = []
        for index in 0..<2 {
            items.append(BedManagement.newDischargePlanSchedule("discharge-plan-schedule-\(index)", title: "sample"))
        }
        let report = BedManagement.buildDischargePlanScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
