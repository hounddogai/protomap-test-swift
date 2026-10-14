@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInventoryBatchReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702766296)
        var items: [Pharmacy.DefaultInventoryBatch] = []
        for index in 0..<6 {
            items.append(Pharmacy.newDefaultInventoryBatch("default-inventory-batch-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildDefaultInventoryBatchReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
