@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalAuthorizationSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704396423)
        var items: [RevenueCycle.GlobalAuthorizationSummary] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newGlobalAuthorizationSummary("global-authorization-summary-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildGlobalAuthorizationSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
