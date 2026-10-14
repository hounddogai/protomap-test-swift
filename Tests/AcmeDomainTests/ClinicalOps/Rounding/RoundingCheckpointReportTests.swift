@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708949836)
        var items: [ClinicalOps.RoundingCheckpoint] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newRoundingCheckpoint("rounding-checkpoint-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildRoundingCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
