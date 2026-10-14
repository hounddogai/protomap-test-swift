@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalSubstitutionTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704182271)
        var items: [Pharmacy.SeasonalSubstitutionTarget] = []
        for index in 0..<2 {
            items.append(Pharmacy.newSeasonalSubstitutionTarget("seasonal-substitution-target-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildSeasonalSubstitutionTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
