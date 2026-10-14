@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredRemittanceAdjustmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707137912)
        var items: [RevenueCycle.TieredRemittanceAdjustment] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newTieredRemittanceAdjustment("tiered-remittance-adjustment-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildTieredRemittanceAdjustmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
