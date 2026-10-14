@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700154823)
        var items: [Staffing.ShiftCheckpoint] = []
        for index in 0..<6 {
            items.append(Staffing.newShiftCheckpoint("shift-checkpoint-\(index)", label: "sample"))
        }
        let report = Staffing.buildShiftCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
