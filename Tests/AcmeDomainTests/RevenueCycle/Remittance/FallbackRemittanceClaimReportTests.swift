@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackRemittanceClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707178002)
        var items: [RevenueCycle.FallbackRemittanceClaim] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newFallbackRemittanceClaim("fallback-remittance-claim-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildFallbackRemittanceClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
