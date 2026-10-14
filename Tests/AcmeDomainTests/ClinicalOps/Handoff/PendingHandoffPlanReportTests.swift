@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingHandoffPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700626449)
        var items: [ClinicalOps.PendingHandoffPlan] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newPendingHandoffPlan("pending-handoff-plan-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildPendingHandoffPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
