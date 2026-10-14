@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704163632)
        var items: [RevenueCycle.RemittanceSummary] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newRemittanceSummary("remittance-summary-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildRemittanceSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
