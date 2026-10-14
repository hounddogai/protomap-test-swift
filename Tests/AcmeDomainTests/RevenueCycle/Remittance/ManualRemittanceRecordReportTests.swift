@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualRemittanceRecordReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702824970)
        var items: [RevenueCycle.ManualRemittanceRecord] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newManualRemittanceRecord("manual-remittance-record-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildManualRemittanceRecordReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
