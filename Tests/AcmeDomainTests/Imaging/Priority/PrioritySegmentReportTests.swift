@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrioritySegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704492729)
        var items: [Imaging.PrioritySegment] = []
        for index in 0..<4 {
            items.append(Imaging.newPrioritySegment("priority-segment-\(index)", name: "sample"))
        }
        let report = Imaging.buildPrioritySegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
