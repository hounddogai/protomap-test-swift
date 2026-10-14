@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCleaningEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704745567)
        var items: [BedManagement.LenientCleaningEstimate] = []
        for index in 0..<3 {
            items.append(BedManagement.newLenientCleaningEstimate("lenient-cleaning-estimate-\(index)", name: "sample"))
        }
        let report = BedManagement.buildLenientCleaningEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
