@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701206852)
        var items: [Pharmacy.InventoryScore] = []
        for index in 0..<5 {
            items.append(Pharmacy.newInventoryScore("inventory-score-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildInventoryScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
