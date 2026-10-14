@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedResultScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703062483)
        var items: [Labs.WeightedResultScore] = []
        for index in 0..<4 {
            items.append(Labs.newWeightedResultScore("weighted-result-score-\(index)", name: "sample"))
        }
        let report = Labs.buildWeightedResultScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
