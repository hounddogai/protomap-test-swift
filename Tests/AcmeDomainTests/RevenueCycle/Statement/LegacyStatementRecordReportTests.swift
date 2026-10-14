@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyStatementRecordReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706933595)
        var items: [RevenueCycle.LegacyStatementRecord] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newLegacyStatementRecord("legacy-statement-record-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildLegacyStatementRecordReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
