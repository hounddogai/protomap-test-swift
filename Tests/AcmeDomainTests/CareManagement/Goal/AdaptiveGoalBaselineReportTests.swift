@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveGoalBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708700452)
        var items: [CareManagement.AdaptiveGoalBaseline] = []
        for index in 0..<3 {
            items.append(CareManagement.newAdaptiveGoalBaseline("adaptive-goal-baseline-\(index)", title: "sample"))
        }
        let report = CareManagement.buildAdaptiveGoalBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
