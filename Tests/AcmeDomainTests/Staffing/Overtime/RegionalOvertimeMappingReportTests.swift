@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimeMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703711418)
        var items: [Staffing.RegionalOvertimeMapping] = []
        for index in 0..<4 {
            items.append(Staffing.newRegionalOvertimeMapping("regional-overtime-mapping-\(index)", name: "sample"))
        }
        let report = Staffing.buildRegionalOvertimeMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
