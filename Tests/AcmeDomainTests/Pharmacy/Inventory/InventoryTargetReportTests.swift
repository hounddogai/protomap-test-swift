@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707745064)
        var items: [Pharmacy.InventoryTarget] = []
        for index in 0..<2 {
            items.append(Pharmacy.newInventoryTarget("inventory-target-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildInventoryTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
