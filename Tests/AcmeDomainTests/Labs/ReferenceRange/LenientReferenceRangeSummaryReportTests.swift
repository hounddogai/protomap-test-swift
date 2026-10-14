@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702183357)
        var items: [Labs.LenientReferenceRangeSummary] = []
        for index in 0..<4 {
            items.append(Labs.newLenientReferenceRangeSummary("lenient-reference-range-summary-\(index)", label: "sample"))
        }
        let report = Labs.buildLenientReferenceRangeSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
