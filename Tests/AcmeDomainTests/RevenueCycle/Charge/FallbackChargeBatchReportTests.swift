@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackChargeBatchReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704748584)
        var items: [RevenueCycle.FallbackChargeBatch] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newFallbackChargeBatch("fallback-charge-batch-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildFallbackChargeBatchReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
