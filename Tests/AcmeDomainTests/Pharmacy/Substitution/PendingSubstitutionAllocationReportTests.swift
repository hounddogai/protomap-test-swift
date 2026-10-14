@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingSubstitutionAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703822567)
        var items: [Pharmacy.PendingSubstitutionAllocation] = []
        for index in 0..<2 {
            items.append(Pharmacy.newPendingSubstitutionAllocation("pending-substitution-allocation-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildPendingSubstitutionAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
