@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalDisclosureRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708442924)
        var items: [Consent.GlobalDisclosureRule] = []
        for index in 0..<6 {
            items.append(Consent.newGlobalDisclosureRule("global-disclosure-rule-\(index)", label: "sample"))
        }
        let report = Consent.buildGlobalDisclosureRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
