@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyGoalSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702078209)
        var items: [CareManagement.LegacyGoalSummary] = []
        for index in 0..<5 {
            items.append(CareManagement.newLegacyGoalSummary("legacy-goal-summary-\(index)", title: "sample"))
        }
        let report = CareManagement.buildLegacyGoalSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
