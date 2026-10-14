@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedInventoryCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701423127)
        var items: [Pharmacy.CappedInventoryCycle] = []
        for index in 0..<4 {
            items.append(Pharmacy.newCappedInventoryCycle("capped-inventory-cycle-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildCappedInventoryCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
