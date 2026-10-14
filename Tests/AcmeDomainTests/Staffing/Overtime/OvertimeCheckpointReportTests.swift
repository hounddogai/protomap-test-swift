@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703334137)
        var items: [Staffing.OvertimeCheckpoint] = []
        for index in 0..<5 {
            items.append(Staffing.newOvertimeCheckpoint("overtime-checkpoint-\(index)", label: "sample"))
        }
        let report = Staffing.buildOvertimeCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
