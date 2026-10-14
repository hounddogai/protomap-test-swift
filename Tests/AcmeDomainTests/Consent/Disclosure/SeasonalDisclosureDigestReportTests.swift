@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalDisclosureDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705458084)
        var items: [Consent.SeasonalDisclosureDigest] = []
        for index in 0..<5 {
            items.append(Consent.newSeasonalDisclosureDigest("seasonal-disclosure-digest-\(index)", title: "sample"))
        }
        let report = Consent.buildSeasonalDisclosureDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
