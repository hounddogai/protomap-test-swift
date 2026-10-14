@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705274830)
        var items: [ClinicalOps.OrderSetThreshold] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newOrderSetThreshold("order-set-threshold-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildOrderSetThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
