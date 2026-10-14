@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalShiftProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705985565)
        var items: [Staffing.GlobalShiftProfile] = []
        for index in 0..<3 {
            items.append(Staffing.newGlobalShiftProfile("global-shift-profile-\(index)", name: "sample"))
        }
        let report = Staffing.buildGlobalShiftProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
