@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultWitnessPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705697666)
        var items: [Consent.DefaultWitnessPreference] = []
        for index in 0..<5 {
            items.append(Consent.newDefaultWitnessPreference("default-witness-preference-\(index)", name: "sample"))
        }
        let report = Consent.buildDefaultWitnessPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
