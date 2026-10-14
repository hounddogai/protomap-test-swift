@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedInventoryBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704619459)
        var items: [Pharmacy.BatchedInventoryBaseline] = []
        for index in 0..<3 {
            items.append(Pharmacy.newBatchedInventoryBaseline("batched-inventory-baseline-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildBatchedInventoryBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
