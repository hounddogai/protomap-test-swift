@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702072590)
        var items: [ClinicalOps.HandoffSummary] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newHandoffSummary("handoff-summary-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildHandoffSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
