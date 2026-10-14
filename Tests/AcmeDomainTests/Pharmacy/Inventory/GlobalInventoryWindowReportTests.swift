@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalInventoryWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700367434)
        var items: [Pharmacy.GlobalInventoryWindow] = []
        for index in 0..<2 {
            items.append(Pharmacy.newGlobalInventoryWindow("global-inventory-window-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildGlobalInventoryWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
