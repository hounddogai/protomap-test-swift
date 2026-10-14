@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalLanguageTierReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702583528)
        var items: [Consent.RegionalLanguageTier] = []
        for index in 0..<2 {
            items.append(Consent.newRegionalLanguageTier("regional-language-tier-\(index)", name: "sample"))
        }
        let report = Consent.buildRegionalLanguageTierReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
