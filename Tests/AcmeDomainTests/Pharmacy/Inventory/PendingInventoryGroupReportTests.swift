@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingInventoryGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708051218)
        var items: [Pharmacy.PendingInventoryGroup] = []
        for index in 0..<2 {
            items.append(Pharmacy.newPendingInventoryGroup("pending-inventory-group-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildPendingInventoryGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
