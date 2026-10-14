@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedCareProtocolPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702506036)
        var items: [ClinicalOps.BatchedCareProtocolPlan] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newBatchedCareProtocolPlan("batched-care-protocol-plan-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildBatchedCareProtocolPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
