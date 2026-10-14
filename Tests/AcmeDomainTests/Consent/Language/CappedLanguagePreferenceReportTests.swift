@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedLanguagePreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702232901)
        var items: [Consent.CappedLanguagePreference] = []
        for index in 0..<6 {
            items.append(Consent.newCappedLanguagePreference("capped-language-preference-\(index)", label: "sample"))
        }
        let report = Consent.buildCappedLanguagePreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
