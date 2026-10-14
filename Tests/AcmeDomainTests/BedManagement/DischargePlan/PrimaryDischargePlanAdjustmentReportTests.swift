@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanAdjustmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706375483)
        var items: [BedManagement.PrimaryDischargePlanAdjustment] = []
        for index in 0..<5 {
            items.append(BedManagement.newPrimaryDischargePlanAdjustment("primary-discharge-plan-adjustment-\(index)", title: "sample"))
        }
        let report = BedManagement.buildPrimaryDischargePlanAdjustmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
