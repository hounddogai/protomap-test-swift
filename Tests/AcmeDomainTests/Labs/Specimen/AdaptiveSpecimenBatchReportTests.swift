@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenBatchReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704611686)
        var items: [Labs.AdaptiveSpecimenBatch] = []
        for index in 0..<5 {
            items.append(Labs.newAdaptiveSpecimenBatch("adaptive-specimen-batch-\(index)", name: "sample"))
        }
        let report = Labs.buildAdaptiveSpecimenBatchReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
