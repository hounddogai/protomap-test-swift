@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700157397)
        var items: [Pharmacy.InventoryMetric] = []
        for index in 0..<2 {
            items.append(Pharmacy.newInventoryMetric("inventory-metric-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildInventoryMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
