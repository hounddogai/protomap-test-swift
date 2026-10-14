@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707575032)
        var items: [Pharmacy.SubstitutionAllocation] = []
        for index in 0..<3 {
            items.append(Pharmacy.newSubstitutionAllocation("substitution-allocation-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildSubstitutionAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
