@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveGoalPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701303024)
        var items: [CareManagement.AdaptiveGoalPreference] = []
        for index in 0..<4 {
            items.append(CareManagement.newAdaptiveGoalPreference("adaptive-goal-preference-\(index)", label: "sample"))
        }
        let report = CareManagement.buildAdaptiveGoalPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
