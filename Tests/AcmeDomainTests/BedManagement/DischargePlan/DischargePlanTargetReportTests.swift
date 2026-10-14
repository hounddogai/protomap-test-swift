@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701864413)
        var items: [BedManagement.DischargePlanTarget] = []
        for index in 0..<3 {
            items.append(BedManagement.newDischargePlanTarget("discharge-plan-target-\(index)", name: "sample"))
        }
        let report = BedManagement.buildDischargePlanTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
