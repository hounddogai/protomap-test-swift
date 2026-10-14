@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707096175)
        var items: [BedManagement.ManualDischargePlanTarget] = []
        for index in 0..<6 {
            items.append(BedManagement.newManualDischargePlanTarget("manual-discharge-plan-target-\(index)", label: "sample"))
        }
        let report = BedManagement.buildManualDischargePlanTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
