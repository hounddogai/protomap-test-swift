@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702475399)
        var items: [BedManagement.PrimaryDischargePlanBaseline] = []
        for index in 0..<2 {
            items.append(BedManagement.newPrimaryDischargePlanBaseline("primary-discharge-plan-baseline-\(index)", title: "sample"))
        }
        let report = BedManagement.buildPrimaryDischargePlanBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
