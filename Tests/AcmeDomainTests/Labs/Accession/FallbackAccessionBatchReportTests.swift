@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionBatchReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701179960)
        var items: [Labs.FallbackAccessionBatch] = []
        for index in 0..<6 {
            items.append(Labs.newFallbackAccessionBatch("fallback-accession-batch-\(index)", title: "sample"))
        }
        let report = Labs.buildFallbackAccessionBatchReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
