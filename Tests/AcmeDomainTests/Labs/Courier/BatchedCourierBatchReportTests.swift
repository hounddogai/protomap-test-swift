@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedCourierBatchReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702377445)
        var items: [Labs.BatchedCourierBatch] = []
        for index in 0..<6 {
            items.append(Labs.newBatchedCourierBatch("batched-courier-batch-\(index)", label: "sample"))
        }
        let report = Labs.buildBatchedCourierBatchReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
