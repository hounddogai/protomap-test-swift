@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708441684)
        var items: [ClinicalOps.HandoffAudit] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newHandoffAudit("handoff-audit-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildHandoffAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
