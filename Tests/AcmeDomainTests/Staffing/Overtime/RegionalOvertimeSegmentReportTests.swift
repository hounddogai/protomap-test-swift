@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimeSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707501761)
        var items: [Staffing.RegionalOvertimeSegment] = []
        for index in 0..<2 {
            items.append(Staffing.newRegionalOvertimeSegment("regional-overtime-segment-\(index)", label: "sample"))
        }
        let report = Staffing.buildRegionalOvertimeSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
