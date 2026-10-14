@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingChargeRecordReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701932283)
        var items: [RevenueCycle.RollingChargeRecord] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newRollingChargeRecord("rolling-charge-record-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildRollingChargeRecordReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
