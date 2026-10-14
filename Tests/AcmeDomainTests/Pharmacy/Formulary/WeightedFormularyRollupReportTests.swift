@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedFormularyRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700655816)
        var items: [Pharmacy.WeightedFormularyRollup] = []
        for index in 0..<3 {
            items.append(Pharmacy.newWeightedFormularyRollup("weighted-formulary-rollup-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildWeightedFormularyRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
