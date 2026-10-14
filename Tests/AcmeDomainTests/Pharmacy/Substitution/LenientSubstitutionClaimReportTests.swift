@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientSubstitutionClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702665697)
        var items: [Pharmacy.LenientSubstitutionClaim] = []
        for index in 0..<6 {
            items.append(Pharmacy.newLenientSubstitutionClaim("lenient-substitution-claim-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildLenientSubstitutionClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
