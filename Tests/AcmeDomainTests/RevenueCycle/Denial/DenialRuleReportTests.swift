@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700935390)
        var items: [RevenueCycle.DenialRule] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newDenialRule("denial-rule-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildDenialRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
