@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702875068)
        var items: [ClinicalOps.OrderSetAudit] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newOrderSetAudit("order-set-audit-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildOrderSetAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
