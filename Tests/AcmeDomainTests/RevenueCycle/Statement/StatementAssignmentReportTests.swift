@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705726844)
        var items: [RevenueCycle.StatementAssignment] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newStatementAssignment("statement-assignment-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildStatementAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
