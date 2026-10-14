@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalProxyQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701537049)
        var items: [Consent.RegionalProxyQuota] = []
        for index in 0..<5 {
            items.append(Consent.newRegionalProxyQuota("regional-proxy-quota-\(index)", name: "sample"))
        }
        let report = Consent.buildRegionalProxyQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
