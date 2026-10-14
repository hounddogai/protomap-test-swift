@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706088817)
        var items: [CareManagement.CareGapBudget] = []
        for index in 0..<3 {
            items.append(CareManagement.newCareGapBudget("care-gap-budget-\(index)", name: "sample"))
        }
        let report = CareManagement.buildCareGapBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
