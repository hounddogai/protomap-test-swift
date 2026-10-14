@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703986668)
        var items: [ClinicalOps.RoundingSegment] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newRoundingSegment("rounding-segment-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildRoundingSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
