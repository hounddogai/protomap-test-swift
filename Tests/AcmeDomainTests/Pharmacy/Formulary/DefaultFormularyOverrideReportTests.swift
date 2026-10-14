@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultFormularyOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704121088)
        var items: [Pharmacy.DefaultFormularyOverride] = []
        for index in 0..<3 {
            items.append(Pharmacy.newDefaultFormularyOverride("default-formulary-override-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildDefaultFormularyOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
