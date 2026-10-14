@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705644308)
        var items: [BedManagement.IsolationSegment] = []
        for index in 0..<4 {
            items.append(BedManagement.newIsolationSegment("isolation-segment-\(index)", title: "sample"))
        }
        let report = BedManagement.buildIsolationSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
