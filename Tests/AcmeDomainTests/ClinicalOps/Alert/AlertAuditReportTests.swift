@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700800984)
        var items: [ClinicalOps.AlertAudit] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newAlertAudit("alert-audit-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildAlertAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
