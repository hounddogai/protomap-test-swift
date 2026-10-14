@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedOrderSetPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705158205)
        var items: [ClinicalOps.BatchedOrderSetPreference] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newBatchedOrderSetPreference("batched-order-set-preference-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildBatchedOrderSetPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
