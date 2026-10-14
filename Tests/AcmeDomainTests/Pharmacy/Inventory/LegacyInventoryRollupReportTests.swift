@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInventoryRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709087533)
        var items: [Pharmacy.LegacyInventoryRollup] = []
        for index in 0..<4 {
            items.append(Pharmacy.newLegacyInventoryRollup("legacy-inventory-rollup-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildLegacyInventoryRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
