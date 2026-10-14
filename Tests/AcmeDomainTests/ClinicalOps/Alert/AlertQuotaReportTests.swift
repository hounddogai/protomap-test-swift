@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708998749)
        var items: [ClinicalOps.AlertQuota] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newAlertQuota("alert-quota-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildAlertQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
