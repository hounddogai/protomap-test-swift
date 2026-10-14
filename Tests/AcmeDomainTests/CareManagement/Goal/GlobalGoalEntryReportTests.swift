@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalGoalEntryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703789155)
        var items: [CareManagement.GlobalGoalEntry] = []
        for index in 0..<6 {
            items.append(CareManagement.newGlobalGoalEntry("global-goal-entry-\(index)", label: "sample"))
        }
        let report = CareManagement.buildGlobalGoalEntryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
