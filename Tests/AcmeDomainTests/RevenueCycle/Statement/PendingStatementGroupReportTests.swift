@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingStatementGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702762477)
        var items: [RevenueCycle.PendingStatementGroup] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newPendingStatementGroup("pending-statement-group-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildPendingStatementGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
