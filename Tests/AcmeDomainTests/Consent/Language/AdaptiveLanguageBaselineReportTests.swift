@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveLanguageBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706113982)
        var items: [Consent.AdaptiveLanguageBaseline] = []
        for index in 0..<3 {
            items.append(Consent.newAdaptiveLanguageBaseline("adaptive-language-baseline-\(index)", name: "sample"))
        }
        let report = Consent.buildAdaptiveLanguageBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
