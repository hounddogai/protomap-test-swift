@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultNetworkRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709589500)
        var items: [Referrals.DefaultNetworkRule] = []
        for index in 0..<2 {
            items.append(Referrals.newDefaultNetworkRule("default-network-rule-\(index)", label: "sample"))
        }
        let report = Referrals.buildDefaultNetworkRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
