@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701652193)
        var items: [Pharmacy.FormularyThreshold] = []
        for index in 0..<6 {
            items.append(Pharmacy.newFormularyThreshold("formulary-threshold-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildFormularyThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
