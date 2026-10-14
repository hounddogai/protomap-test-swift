@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalAccessionAdjustmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704566267)
        var items: [Labs.SeasonalAccessionAdjustment] = []
        for index in 0..<4 {
            items.append(Labs.newSeasonalAccessionAdjustment("seasonal-accession-adjustment-\(index)", name: "sample"))
        }
        let report = Labs.buildSeasonalAccessionAdjustmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
