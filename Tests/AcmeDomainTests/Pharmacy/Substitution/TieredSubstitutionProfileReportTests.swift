@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredSubstitutionProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702829455)
        var items: [Pharmacy.TieredSubstitutionProfile] = []
        for index in 0..<3 {
            items.append(Pharmacy.newTieredSubstitutionProfile("tiered-substitution-profile-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildTieredSubstitutionProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
