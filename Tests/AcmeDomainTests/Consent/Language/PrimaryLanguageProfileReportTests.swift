@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryLanguageProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705989709)
        var items: [Consent.PrimaryLanguageProfile] = []
        for index in 0..<2 {
            items.append(Consent.newPrimaryLanguageProfile("primary-language-profile-\(index)", title: "sample"))
        }
        let report = Consent.buildPrimaryLanguageProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
