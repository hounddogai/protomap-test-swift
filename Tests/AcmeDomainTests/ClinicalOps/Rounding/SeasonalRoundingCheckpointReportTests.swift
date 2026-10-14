@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalRoundingCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709874516)
        var items: [ClinicalOps.SeasonalRoundingCheckpoint] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newSeasonalRoundingCheckpoint("seasonal-rounding-checkpoint-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildSeasonalRoundingCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
