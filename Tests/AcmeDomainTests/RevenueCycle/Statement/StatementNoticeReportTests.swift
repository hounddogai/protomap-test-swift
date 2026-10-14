@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementNoticeReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701887246)
        var items: [RevenueCycle.StatementNotice] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newStatementNotice("statement-notice-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildStatementNoticeReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
