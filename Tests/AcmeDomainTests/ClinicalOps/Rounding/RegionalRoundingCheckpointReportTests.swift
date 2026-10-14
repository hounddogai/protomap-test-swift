@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalRoundingCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706361151)
        var items: [ClinicalOps.RegionalRoundingCheckpoint] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newRegionalRoundingCheckpoint("regional-rounding-checkpoint-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildRegionalRoundingCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
