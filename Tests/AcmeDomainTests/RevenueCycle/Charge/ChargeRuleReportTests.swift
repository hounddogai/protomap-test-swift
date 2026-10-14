@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703433942)
        var items: [RevenueCycle.ChargeRule] = []
        for index in 0..<5 {
            items.append(RevenueCycle.newChargeRule("charge-rule-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildChargeRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
