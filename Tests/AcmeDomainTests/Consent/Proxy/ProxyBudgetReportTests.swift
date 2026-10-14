@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708124154)
        var items: [Consent.ProxyBudget] = []
        for index in 0..<5 {
            items.append(Consent.newProxyBudget("proxy-budget-\(index)", name: "sample"))
        }
        let report = Consent.buildProxyBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
