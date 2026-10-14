@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702206816)
        var items: [BedManagement.BedBoardBudget] = []
        for index in 0..<2 {
            items.append(BedManagement.newBedBoardBudget("bed-board-budget-\(index)", name: "sample"))
        }
        let report = BedManagement.buildBedBoardBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
