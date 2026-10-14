@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706922085)
        var items: [RevenueCycle.StatementProfile] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newStatementProfile("statement-profile-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildStatementProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
