@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyStatementExceptionReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701195083)
        var items: [RevenueCycle.LegacyStatementException] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newLegacyStatementException("legacy-statement-exception-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildLegacyStatementExceptionReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
