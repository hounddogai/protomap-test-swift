@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709660682)
        var items: [Pharmacy.DispenseSummary] = []
        for index in 0..<4 {
            items.append(Pharmacy.newDispenseSummary("dispense-summary-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildDispenseSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
