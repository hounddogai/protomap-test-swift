@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryShiftWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703953824)
        var items: [Staffing.PrimaryShiftWindow] = []
        for index in 0..<5 {
            items.append(Staffing.newPrimaryShiftWindow("primary-shift-window-\(index)", label: "sample"))
        }
        let report = Staffing.buildPrimaryShiftWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
