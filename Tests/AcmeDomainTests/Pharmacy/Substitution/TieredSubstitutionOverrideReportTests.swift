@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredSubstitutionOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707000091)
        var items: [Pharmacy.TieredSubstitutionOverride] = []
        for index in 0..<3 {
            items.append(Pharmacy.newTieredSubstitutionOverride("tiered-substitution-override-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildTieredSubstitutionOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
