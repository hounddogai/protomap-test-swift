@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704609359)
        var items: [Labs.ResultCheckpoint] = []
        for index in 0..<5 {
            items.append(Labs.newResultCheckpoint("result-checkpoint-\(index)", name: "sample"))
        }
        let report = Labs.buildResultCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
