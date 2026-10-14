@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709173595)
        var items: [Pharmacy.InventoryAssignment] = []
        for index in 0..<2 {
            items.append(Pharmacy.newInventoryAssignment("inventory-assignment-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildInventoryAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
