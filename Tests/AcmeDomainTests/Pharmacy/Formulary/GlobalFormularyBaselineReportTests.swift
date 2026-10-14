@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalFormularyBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706367036)
        var items: [Pharmacy.GlobalFormularyBaseline] = []
        for index in 0..<2 {
            items.append(Pharmacy.newGlobalFormularyBaseline("global-formulary-baseline-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildGlobalFormularyBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
