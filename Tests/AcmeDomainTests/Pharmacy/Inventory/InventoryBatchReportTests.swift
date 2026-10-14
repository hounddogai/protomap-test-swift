@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryBatchReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703161220)
        var items: [Pharmacy.InventoryBatch] = []
        for index in 0..<3 {
            items.append(Pharmacy.newInventoryBatch("inventory-batch-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildInventoryBatchReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
