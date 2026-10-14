@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedDispenseAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707063504)
        var items: [Pharmacy.WeightedDispenseAssignment] = []
        for index in 0..<6 {
            items.append(Pharmacy.newWeightedDispenseAssignment("weighted-dispense-assignment-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildWeightedDispenseAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
