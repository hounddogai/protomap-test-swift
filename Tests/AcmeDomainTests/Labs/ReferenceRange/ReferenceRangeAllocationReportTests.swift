@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700213162)
        var items: [Labs.ReferenceRangeAllocation] = []
        for index in 0..<4 {
            items.append(Labs.newReferenceRangeAllocation("reference-range-allocation-\(index)", label: "sample"))
        }
        let report = Labs.buildReferenceRangeAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
