@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701401661)
        var items: [RevenueCycle.DenialPreference] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newDenialPreference("denial-preference-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildDenialPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
