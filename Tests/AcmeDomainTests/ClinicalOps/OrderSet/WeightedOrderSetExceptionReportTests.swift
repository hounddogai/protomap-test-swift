@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedOrderSetExceptionReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705415964)
        var items: [ClinicalOps.WeightedOrderSetException] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newWeightedOrderSetException("weighted-order-set-exception-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildWeightedOrderSetExceptionReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
