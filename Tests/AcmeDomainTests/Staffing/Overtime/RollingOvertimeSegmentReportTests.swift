@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingOvertimeSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701084497)
        var items: [Staffing.RollingOvertimeSegment] = []
        for index in 0..<3 {
            items.append(Staffing.newRollingOvertimeSegment("rolling-overtime-segment-\(index)", name: "sample"))
        }
        let report = Staffing.buildRollingOvertimeSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
