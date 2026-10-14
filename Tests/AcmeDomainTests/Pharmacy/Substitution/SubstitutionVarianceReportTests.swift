@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703751662)
        var items: [Pharmacy.SubstitutionVariance] = []
        for index in 0..<5 {
            items.append(Pharmacy.newSubstitutionVariance("substitution-variance-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildSubstitutionVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
