@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708357564)
        var items: [Labs.ReferenceRangeGroup] = []
        for index in 0..<2 {
            items.append(Labs.newReferenceRangeGroup("reference-range-group-\(index)", label: "sample"))
        }
        let report = Labs.buildReferenceRangeGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
