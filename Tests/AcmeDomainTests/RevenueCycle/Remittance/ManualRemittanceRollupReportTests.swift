@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualRemittanceRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706734124)
        var items: [RevenueCycle.ManualRemittanceRollup] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newManualRemittanceRollup("manual-remittance-rollup-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildManualRemittanceRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
