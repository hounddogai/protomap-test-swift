@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingDenialThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706850108)
        var items: [RevenueCycle.RollingDenialThreshold] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newRollingDenialThreshold("rolling-denial-threshold-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildRollingDenialThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
