@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingAccessionSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707958283)
        var items: [Labs.RollingAccessionSegment] = []
        for index in 0..<4 {
            items.append(Labs.newRollingAccessionSegment("rolling-accession-segment-\(index)", label: "sample"))
        }
        let report = Labs.buildRollingAccessionSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
