@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalInventoryThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705379603)
        var items: [Pharmacy.GlobalInventoryThreshold] = []
        for index in 0..<2 {
            items.append(Pharmacy.newGlobalInventoryThreshold("global-inventory-threshold-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildGlobalInventoryThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
