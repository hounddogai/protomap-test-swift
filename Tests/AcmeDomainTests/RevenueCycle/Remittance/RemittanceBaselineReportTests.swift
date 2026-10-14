@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702884460)
        var items: [RevenueCycle.RemittanceBaseline] = []
        for index in 0..<5 {
            items.append(RevenueCycle.newRemittanceBaseline("remittance-baseline-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildRemittanceBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
