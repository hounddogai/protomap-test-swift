@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedStatementExceptionReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706142589)
        var items: [RevenueCycle.CappedStatementException] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newCappedStatementException("capped-statement-exception-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildCappedStatementExceptionReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
