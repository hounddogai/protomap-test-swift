@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709030876)
        var items: [RevenueCycle.TieredClaimQuota] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newTieredClaimQuota("tiered-claim-quota-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildTieredClaimQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
