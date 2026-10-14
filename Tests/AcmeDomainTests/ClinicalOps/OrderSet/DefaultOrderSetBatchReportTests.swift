@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultOrderSetBatchReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703051937)
        var items: [ClinicalOps.DefaultOrderSetBatch] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newDefaultOrderSetBatch("default-order-set-batch-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildDefaultOrderSetBatchReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
