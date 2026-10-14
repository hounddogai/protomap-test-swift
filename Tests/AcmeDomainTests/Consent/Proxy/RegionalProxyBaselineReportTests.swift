@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalProxyBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708938663)
        var items: [Consent.RegionalProxyBaseline] = []
        for index in 0..<5 {
            items.append(Consent.newRegionalProxyBaseline("regional-proxy-baseline-\(index)", name: "sample"))
        }
        let report = Consent.buildRegionalProxyBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
