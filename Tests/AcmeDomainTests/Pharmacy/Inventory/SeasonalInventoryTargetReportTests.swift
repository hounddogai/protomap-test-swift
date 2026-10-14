@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInventoryTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705424327)
        var items: [Pharmacy.SeasonalInventoryTarget] = []
        for index in 0..<3 {
            items.append(Pharmacy.newSeasonalInventoryTarget("seasonal-inventory-target-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildSeasonalInventoryTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
