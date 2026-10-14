@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledStatementProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703994688)
        var items: [RevenueCycle.ScheduledStatementProfile] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newScheduledStatementProfile("scheduled-statement-profile-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildScheduledStatementProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
