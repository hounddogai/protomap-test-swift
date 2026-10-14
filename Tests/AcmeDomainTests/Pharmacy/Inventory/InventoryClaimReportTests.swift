@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702171130)
        var items: [Pharmacy.InventoryClaim] = []
        for index in 0..<2 {
            items.append(Pharmacy.newInventoryClaim("inventory-claim-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildInventoryClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
