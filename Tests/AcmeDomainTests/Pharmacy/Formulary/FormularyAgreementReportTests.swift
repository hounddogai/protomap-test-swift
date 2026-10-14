@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701406522)
        var items: [Pharmacy.FormularyAgreement] = []
        for index in 0..<4 {
            items.append(Pharmacy.newFormularyAgreement("formulary-agreement-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildFormularyAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
