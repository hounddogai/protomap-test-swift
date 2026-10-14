@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703081334)
        var items: [Labs.RollingPanelPlan] = []
        for index in 0..<3 {
            items.append(Labs.newRollingPanelPlan("rolling-panel-plan-\(index)", label: "sample"))
        }
        let report = Labs.buildRollingPanelPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
