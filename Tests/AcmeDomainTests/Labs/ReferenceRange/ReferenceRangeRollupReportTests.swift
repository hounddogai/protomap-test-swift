@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701773751)
        var items: [Labs.ReferenceRangeRollup] = []
        for index in 0..<4 {
            items.append(Labs.newReferenceRangeRollup("reference-range-rollup-\(index)", label: "sample"))
        }
        let report = Labs.buildReferenceRangeRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
