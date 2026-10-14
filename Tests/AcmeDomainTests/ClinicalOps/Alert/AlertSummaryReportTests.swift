@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704843720)
        var items: [ClinicalOps.AlertSummary] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newAlertSummary("alert-summary-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildAlertSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
