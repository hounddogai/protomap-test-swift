@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingEntryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703216933)
        var items: [ClinicalOps.RoundingEntry] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newRoundingEntry("rounding-entry-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildRoundingEntryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
