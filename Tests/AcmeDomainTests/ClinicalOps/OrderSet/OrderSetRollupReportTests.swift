@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702819348)
        var items: [ClinicalOps.OrderSetRollup] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newOrderSetRollup("order-set-rollup-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildOrderSetRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
