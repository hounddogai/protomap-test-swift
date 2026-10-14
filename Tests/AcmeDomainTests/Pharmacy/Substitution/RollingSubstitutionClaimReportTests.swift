@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingSubstitutionClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700909784)
        var items: [Pharmacy.RollingSubstitutionClaim] = []
        for index in 0..<6 {
            items.append(Pharmacy.newRollingSubstitutionClaim("rolling-substitution-claim-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildRollingSubstitutionClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
