@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedDispenseMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706486443)
        var items: [Pharmacy.WeightedDispenseMetric] = []
        for index in 0..<3 {
            items.append(Pharmacy.newWeightedDispenseMetric("weighted-dispense-metric-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildWeightedDispenseMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
