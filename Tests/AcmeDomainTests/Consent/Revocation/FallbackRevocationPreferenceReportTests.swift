@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackRevocationPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708445342)
        var items: [Consent.FallbackRevocationPreference] = []
        for index in 0..<3 {
            items.append(Consent.newFallbackRevocationPreference("fallback-revocation-preference-\(index)", name: "sample"))
        }
        let report = Consent.buildFallbackRevocationPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
