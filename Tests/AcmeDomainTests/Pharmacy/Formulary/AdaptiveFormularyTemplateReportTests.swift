@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveFormularyTemplateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703389171)
        var items: [Pharmacy.AdaptiveFormularyTemplate] = []
        for index in 0..<3 {
            items.append(Pharmacy.newAdaptiveFormularyTemplate("adaptive-formulary-template-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildAdaptiveFormularyTemplateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
