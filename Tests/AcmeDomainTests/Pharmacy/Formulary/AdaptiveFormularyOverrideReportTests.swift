@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveFormularyOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704537231)
        var items: [Pharmacy.AdaptiveFormularyOverride] = []
        for index in 0..<3 {
            items.append(Pharmacy.newAdaptiveFormularyOverride("adaptive-formulary-override-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildAdaptiveFormularyOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
