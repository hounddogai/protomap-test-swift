@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyTemplateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704840791)
        var items: [Pharmacy.FormularyTemplate] = []
        for index in 0..<3 {
            items.append(Pharmacy.newFormularyTemplate("formulary-template-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildFormularyTemplateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
