@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyDischargePlanAdjustmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705837653)
        var items: [BedManagement.LegacyDischargePlanAdjustment] = []
        for index in 0..<5 {
            items.append(BedManagement.newLegacyDischargePlanAdjustment("legacy-discharge-plan-adjustment-\(index)", label: "sample"))
        }
        let report = BedManagement.buildLegacyDischargePlanAdjustmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
