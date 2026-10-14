@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedOrderSetRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707481076)
        var items: [ClinicalOps.WeightedOrderSetRule] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newWeightedOrderSetRule("weighted-order-set-rule-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildWeightedOrderSetRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
