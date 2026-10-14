@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyDisclosureBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703384565)
        var items: [Consent.LegacyDisclosureBaseline] = []
        for index in 0..<5 {
            items.append(Consent.newLegacyDisclosureBaseline("legacy-disclosure-baseline-\(index)", name: "sample"))
        }
        let report = Consent.buildLegacyDisclosureBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
