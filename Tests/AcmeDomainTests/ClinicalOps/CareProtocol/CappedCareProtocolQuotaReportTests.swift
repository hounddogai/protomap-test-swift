@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedCareProtocolQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709949658)
        var items: [ClinicalOps.CappedCareProtocolQuota] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newCappedCareProtocolQuota("capped-care-protocol-quota-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildCappedCareProtocolQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
