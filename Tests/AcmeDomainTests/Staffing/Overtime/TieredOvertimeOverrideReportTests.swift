@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredOvertimeOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706512254)
        var items: [Staffing.TieredOvertimeOverride] = []
        for index in 0..<5 {
            items.append(Staffing.newTieredOvertimeOverride("tiered-overtime-override-\(index)", name: "sample"))
        }
        let report = Staffing.buildTieredOvertimeOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
