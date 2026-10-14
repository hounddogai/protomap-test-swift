@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredRemittanceCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708299892)
        var items: [RevenueCycle.TieredRemittanceCheckpoint] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newTieredRemittanceCheckpoint("tiered-remittance-checkpoint-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildTieredRemittanceCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
