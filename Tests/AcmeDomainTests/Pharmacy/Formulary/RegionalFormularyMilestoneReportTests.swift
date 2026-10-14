@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalFormularyMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709579945)
        var items: [Pharmacy.RegionalFormularyMilestone] = []
        for index in 0..<2 {
            items.append(Pharmacy.newRegionalFormularyMilestone("regional-formulary-milestone-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildRegionalFormularyMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
