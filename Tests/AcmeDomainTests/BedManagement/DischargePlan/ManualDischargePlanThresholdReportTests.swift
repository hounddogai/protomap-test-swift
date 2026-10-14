@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704365314)
        var items: [BedManagement.ManualDischargePlanThreshold] = []
        for index in 0..<3 {
            items.append(BedManagement.newManualDischargePlanThreshold("manual-discharge-plan-threshold-\(index)", label: "sample"))
        }
        let report = BedManagement.buildManualDischargePlanThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
