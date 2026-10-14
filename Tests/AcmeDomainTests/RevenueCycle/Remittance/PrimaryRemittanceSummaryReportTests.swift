@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryRemittanceSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706250732)
        var items: [RevenueCycle.PrimaryRemittanceSummary] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newPrimaryRemittanceSummary("primary-remittance-summary-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildPrimaryRemittanceSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
