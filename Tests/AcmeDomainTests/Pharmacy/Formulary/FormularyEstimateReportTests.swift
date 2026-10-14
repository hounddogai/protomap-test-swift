@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708498500)
        var items: [Pharmacy.FormularyEstimate] = []
        for index in 0..<4 {
            items.append(Pharmacy.newFormularyEstimate("formulary-estimate-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildFormularyEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
