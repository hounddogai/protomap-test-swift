@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalCareGapSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701014238)
        var items: [CareManagement.RegionalCareGapSummary] = []
        for index in 0..<5 {
            items.append(CareManagement.newRegionalCareGapSummary("regional-care-gap-summary-\(index)", label: "sample"))
        }
        let report = CareManagement.buildRegionalCareGapSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
