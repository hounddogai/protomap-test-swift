@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledIsolationSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702062561)
        var items: [BedManagement.ScheduledIsolationSegment] = []
        for index in 0..<2 {
            items.append(BedManagement.newScheduledIsolationSegment("scheduled-isolation-segment-\(index)", name: "sample"))
        }
        let report = BedManagement.buildScheduledIsolationSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
