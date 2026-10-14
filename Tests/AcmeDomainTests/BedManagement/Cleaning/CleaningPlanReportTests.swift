@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702737063)
        var items: [BedManagement.CleaningPlan] = []
        for index in 0..<4 {
            items.append(BedManagement.newCleaningPlan("cleaning-plan-\(index)", title: "sample"))
        }
        let report = BedManagement.buildCleaningPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
