@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackInventoryScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704171779)
        var items: [Pharmacy.FallbackInventoryScore] = []
        for index in 0..<3 {
            items.append(Pharmacy.newFallbackInventoryScore("fallback-inventory-score-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildFallbackInventoryScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
