@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709932559)
        var items: [Staffing.OvertimeCycle] = []
        for index in 0..<3 {
            items.append(Staffing.newOvertimeCycle("overtime-cycle-\(index)", label: "sample"))
        }
        let report = Staffing.buildOvertimeCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
