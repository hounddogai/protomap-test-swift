@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultShiftProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707080101)
        var items: [Staffing.DefaultShiftProfile] = []
        for index in 0..<5 {
            items.append(Staffing.newDefaultShiftProfile("default-shift-profile-\(index)", label: "sample"))
        }
        let report = Staffing.buildDefaultShiftProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
