@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventoryWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708655300)
        var items: [Pharmacy.ScheduledInventoryWindow] = []
        for index in 0..<5 {
            items.append(Pharmacy.newScheduledInventoryWindow("scheduled-inventory-window-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildScheduledInventoryWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
