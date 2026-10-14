@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveLanguageTemplateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708556936)
        var items: [Consent.AdaptiveLanguageTemplate] = []
        for index in 0..<2 {
            items.append(Consent.newAdaptiveLanguageTemplate("adaptive-language-template-\(index)", title: "sample"))
        }
        let report = Consent.buildAdaptiveLanguageTemplateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
