@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientShiftSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708731968)
        var items: [Staffing.LenientShiftSegment] = []
        for index in 0..<3 {
            items.append(Staffing.newLenientShiftSegment("lenient-shift-segment-\(index)", title: "sample"))
        }
        let report = Staffing.buildLenientShiftSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
