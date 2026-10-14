@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709350824)
        var items: [RevenueCycle.StatementScore] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newStatementScore("statement-score-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildStatementScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
