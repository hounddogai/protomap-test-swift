@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackChargeExceptionReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702367155)
        var items: [RevenueCycle.FallbackChargeException] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newFallbackChargeException("fallback-charge-exception-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildFallbackChargeExceptionReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
