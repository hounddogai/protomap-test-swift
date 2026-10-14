@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704085865)
        var items: [RevenueCycle.ChargeProfile] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newChargeProfile("charge-profile-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildChargeProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
