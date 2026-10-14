@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704645263)
        var items: [Labs.ReferenceRangeSegment] = []
        for index in 0..<2 {
            items.append(Labs.newReferenceRangeSegment("reference-range-segment-\(index)", name: "sample"))
        }
        let report = Labs.buildReferenceRangeSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
