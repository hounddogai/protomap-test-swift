@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacySubstitutionClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709377598)
        var items: [Pharmacy.LegacySubstitutionClaim] = []
        for index in 0..<2 {
            items.append(Pharmacy.newLegacySubstitutionClaim("legacy-substitution-claim-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildLegacySubstitutionClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
