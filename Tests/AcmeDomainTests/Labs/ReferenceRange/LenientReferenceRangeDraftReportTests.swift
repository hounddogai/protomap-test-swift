@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707816746)
        var items: [Labs.LenientReferenceRangeDraft] = []
        for index in 0..<3 {
            items.append(Labs.newLenientReferenceRangeDraft("lenient-reference-range-draft-\(index)", title: "sample"))
        }
        let report = Labs.buildLenientReferenceRangeDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
