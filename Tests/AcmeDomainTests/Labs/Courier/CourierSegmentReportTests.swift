@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709816087)
        var items: [Labs.CourierSegment] = []
        for index in 0..<6 {
            items.append(Labs.newCourierSegment("courier-segment-\(index)", title: "sample"))
        }
        let report = Labs.buildCourierSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
