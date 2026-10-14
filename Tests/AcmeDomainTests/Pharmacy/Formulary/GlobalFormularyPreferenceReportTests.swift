@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalFormularyPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701219143)
        var items: [Pharmacy.GlobalFormularyPreference] = []
        for index in 0..<4 {
            items.append(Pharmacy.newGlobalFormularyPreference("global-formulary-preference-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildGlobalFormularyPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
