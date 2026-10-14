@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedLanguageBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707228502)
        var items: [Consent.CappedLanguageBundle] = []
        for index in 0..<2 {
            items.append(Consent.newCappedLanguageBundle("capped-language-bundle-\(index)", label: "sample"))
        }
        let report = Consent.buildCappedLanguageBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
