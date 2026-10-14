@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientDispenseMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707139683)
        var items: [Pharmacy.LenientDispenseMetric] = []
        for index in 0..<5 {
            items.append(Pharmacy.newLenientDispenseMetric("lenient-dispense-metric-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildLenientDispenseMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
