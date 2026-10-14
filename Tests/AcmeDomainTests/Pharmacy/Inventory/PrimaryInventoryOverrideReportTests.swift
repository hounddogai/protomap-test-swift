@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInventoryOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709721920)
        var items: [Pharmacy.PrimaryInventoryOverride] = []
        for index in 0..<2 {
            items.append(Pharmacy.newPrimaryInventoryOverride("primary-inventory-override-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildPrimaryInventoryOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
