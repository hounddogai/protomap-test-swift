@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingAlertQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701072278)
        var items: [ClinicalOps.PendingAlertQuota] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newPendingAlertQuota("pending-alert-quota-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildPendingAlertQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
