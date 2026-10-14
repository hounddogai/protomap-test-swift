@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredLanguageProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705510252)
        var items: [Consent.TieredLanguageProfile] = []
        for index in 0..<3 {
            items.append(Consent.newTieredLanguageProfile("tiered-language-profile-\(index)", title: "sample"))
        }
        let report = Consent.buildTieredLanguageProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
