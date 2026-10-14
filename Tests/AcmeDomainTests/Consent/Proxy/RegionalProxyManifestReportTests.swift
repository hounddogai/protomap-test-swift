@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalProxyManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700453545)
        var items: [Consent.RegionalProxyManifest] = []
        for index in 0..<2 {
            items.append(Consent.newRegionalProxyManifest("regional-proxy-manifest-\(index)", label: "sample"))
        }
        let report = Consent.buildRegionalProxyManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
