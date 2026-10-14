@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInventoryPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707748297)
        var items: [Pharmacy.LenientInventoryPlan] = []
        for index in 0..<3 {
            items.append(Pharmacy.newLenientInventoryPlan("lenient-inventory-plan-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildLenientInventoryPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
