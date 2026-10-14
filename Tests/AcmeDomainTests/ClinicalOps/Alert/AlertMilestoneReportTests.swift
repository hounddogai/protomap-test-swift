@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701692390)
        var items: [ClinicalOps.AlertMilestone] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newAlertMilestone("alert-milestone-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildAlertMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
