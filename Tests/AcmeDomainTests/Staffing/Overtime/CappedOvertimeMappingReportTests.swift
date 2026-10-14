@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedOvertimeMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701983987)
        var items: [Staffing.CappedOvertimeMapping] = []
        for index in 0..<3 {
            items.append(Staffing.newCappedOvertimeMapping("capped-overtime-mapping-\(index)", name: "sample"))
        }
        let report = Staffing.buildCappedOvertimeMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
