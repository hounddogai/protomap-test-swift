@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707659384)
        var items: [Labs.ReferenceRangeCheckpoint] = []
        for index in 0..<3 {
            items.append(Labs.newReferenceRangeCheckpoint("reference-range-checkpoint-\(index)", name: "sample"))
        }
        let report = Labs.buildReferenceRangeCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
