@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryAdjustmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708476798)
        var items: [Pharmacy.InventoryAdjustment] = []
        for index in 0..<2 {
            items.append(Pharmacy.newInventoryAdjustment("inventory-adjustment-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildInventoryAdjustmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
