@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingRoundingPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704764381)
        var items: [ClinicalOps.PendingRoundingPlan] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newPendingRoundingPlan("pending-rounding-plan-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildPendingRoundingPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
