@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryBedBoardPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709288184)
        var items: [BedManagement.PrimaryBedBoardPlan] = []
        for index in 0..<2 {
            items.append(BedManagement.newPrimaryBedBoardPlan("primary-bed-board-plan-\(index)", name: "sample"))
        }
        let report = BedManagement.buildPrimaryBedBoardPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
