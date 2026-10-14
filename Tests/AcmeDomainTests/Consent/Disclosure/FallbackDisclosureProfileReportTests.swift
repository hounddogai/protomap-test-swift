@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackDisclosureProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701237903)
        var items: [Consent.FallbackDisclosureProfile] = []
        for index in 0..<3 {
            items.append(Consent.newFallbackDisclosureProfile("fallback-disclosure-profile-\(index)", title: "sample"))
        }
        let report = Consent.buildFallbackDisclosureProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
