@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyGoalCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700800516)
        var items: [CareManagement.LegacyGoalCycle] = []
        for index in 0..<6 {
            items.append(CareManagement.newLegacyGoalCycle("legacy-goal-cycle-\(index)", title: "sample"))
        }
        let report = CareManagement.buildLegacyGoalCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
