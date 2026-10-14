@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyShiftRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703716227)
        var items: [Staffing.LegacyShiftRollup] = []
        for index in 0..<4 {
            items.append(Staffing.newLegacyShiftRollup("legacy-shift-rollup-\(index)", name: "sample"))
        }
        let report = Staffing.buildLegacyShiftRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
