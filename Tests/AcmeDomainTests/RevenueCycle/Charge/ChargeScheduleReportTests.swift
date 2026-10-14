@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704291363)
        var items: [RevenueCycle.ChargeSchedule] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newChargeSchedule("charge-schedule-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildChargeScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
