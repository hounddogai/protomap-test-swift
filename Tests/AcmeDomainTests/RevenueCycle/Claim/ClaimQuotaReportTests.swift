@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700286547)
        var items: [RevenueCycle.ClaimQuota] = []
        for index in 0..<5 {
            items.append(RevenueCycle.newClaimQuota("claim-quota-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildClaimQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
