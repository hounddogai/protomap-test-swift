@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707811968)
        var items: [RevenueCycle.StatementGroup] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newStatementGroup("statement-group-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildStatementGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
