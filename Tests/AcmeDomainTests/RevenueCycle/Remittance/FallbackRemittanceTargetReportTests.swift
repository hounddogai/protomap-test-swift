@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackRemittanceTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700068986)
        var items: [RevenueCycle.FallbackRemittanceTarget] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newFallbackRemittanceTarget("fallback-remittance-target-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildFallbackRemittanceTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
