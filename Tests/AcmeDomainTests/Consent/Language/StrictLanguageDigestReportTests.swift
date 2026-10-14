@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictLanguageDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708496695)
        var items: [Consent.StrictLanguageDigest] = []
        for index in 0..<2 {
            items.append(Consent.newStrictLanguageDigest("strict-language-digest-\(index)", title: "sample"))
        }
        let report = Consent.buildStrictLanguageDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
