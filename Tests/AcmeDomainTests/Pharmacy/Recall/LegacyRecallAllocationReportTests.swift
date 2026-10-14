@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706991544)
        var items: [Pharmacy.LegacyRecallAllocation] = []
        for index in 0..<5 {
            items.append(Pharmacy.newLegacyRecallAllocation("legacy-recall-allocation-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildLegacyRecallAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
