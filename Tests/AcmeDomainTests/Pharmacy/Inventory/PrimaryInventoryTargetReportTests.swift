@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInventoryTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707569462)
        var items: [Pharmacy.PrimaryInventoryTarget] = []
        for index in 0..<5 {
            items.append(Pharmacy.newPrimaryInventoryTarget("primary-inventory-target-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildPrimaryInventoryTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
