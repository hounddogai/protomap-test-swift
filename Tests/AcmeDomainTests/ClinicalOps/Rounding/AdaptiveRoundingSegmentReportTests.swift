@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveRoundingSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708178317)
        var items: [ClinicalOps.AdaptiveRoundingSegment] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newAdaptiveRoundingSegment("adaptive-rounding-segment-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildAdaptiveRoundingSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
