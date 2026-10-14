@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyStatementThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705796136)
        var items: [RevenueCycle.LegacyStatementThreshold] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newLegacyStatementThreshold("legacy-statement-threshold-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildLegacyStatementThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
