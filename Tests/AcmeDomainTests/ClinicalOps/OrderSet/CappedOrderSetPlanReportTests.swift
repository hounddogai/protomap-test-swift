@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedOrderSetPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704760495)
        var items: [ClinicalOps.CappedOrderSetPlan] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newCappedOrderSetPlan("capped-order-set-plan-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildCappedOrderSetPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
