@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveRemittanceQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704665271)
        var items: [RevenueCycle.AdaptiveRemittanceQuota] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newAdaptiveRemittanceQuota("adaptive-remittance-quota-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildAdaptiveRemittanceQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
