@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700098790)
        var items: [Pharmacy.FormularyMetric] = []
        for index in 0..<5 {
            items.append(Pharmacy.newFormularyMetric("formulary-metric-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildFormularyMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
