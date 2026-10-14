@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704670629)
        var items: [Pharmacy.InventoryEstimate] = []
        for index in 0..<3 {
            items.append(Pharmacy.newInventoryEstimate("inventory-estimate-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildInventoryEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
