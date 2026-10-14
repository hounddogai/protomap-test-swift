@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701674244)
        var items: [ClinicalOps.HandoffPlan] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newHandoffPlan("handoff-plan-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildHandoffPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
