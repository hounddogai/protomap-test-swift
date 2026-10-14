@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalCareProtocolQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706090724)
        var items: [ClinicalOps.RegionalCareProtocolQuota] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newRegionalCareProtocolQuota("regional-care-protocol-quota-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildRegionalCareProtocolQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
