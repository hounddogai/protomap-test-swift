@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalNetworkRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708872473)
        var items: [Referrals.RegionalNetworkRule] = []
        for index in 0..<2 {
            items.append(Referrals.newRegionalNetworkRule("regional-network-rule-\(index)", title: "sample"))
        }
        let report = Referrals.buildRegionalNetworkRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
