@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704954977)
        var items: [Staffing.OvertimeMilestone] = []
        for index in 0..<4 {
            items.append(Staffing.newOvertimeMilestone("overtime-milestone-\(index)", name: "sample"))
        }
        let report = Staffing.buildOvertimeMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
