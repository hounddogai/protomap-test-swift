@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708530942)
        var items: [Staffing.OvertimeMapping] = []
        for index in 0..<2 {
            items.append(Staffing.newOvertimeMapping("overtime-mapping-\(index)", title: "sample"))
        }
        let report = Staffing.buildOvertimeMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
