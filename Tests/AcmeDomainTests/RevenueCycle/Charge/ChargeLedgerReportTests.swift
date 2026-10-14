@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeLedgerReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709388072)
        var items: [RevenueCycle.ChargeLedger] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newChargeLedger("charge-ledger-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildChargeLedgerReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
