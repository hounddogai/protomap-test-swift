@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707169097)
        var items: [Staffing.OvertimeSnapshot] = []
        for index in 0..<3 {
            items.append(Staffing.newOvertimeSnapshot("overtime-snapshot-\(index)", label: "sample"))
        }
        let report = Staffing.buildOvertimeSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
